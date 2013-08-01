package Atlassian::EditConfluence;

our
$VERSION = 0.01;


############
## IMPORTS
############

use strict;
use Carp;

use RPC::XML;
use RPC::XML::Client;
# use RPC::XML::request;

#Define acceptable object fields
use fields qw/
	api
	cachedPageTitles
	client
	errstr
	defaultMinor
	defaultSpace
	defaultSummary
	specialSend
	token
	trace
/;


########################
## CONFIG AND DEFAULTS
########################

#Tell RPC::XML to encode data as strings.
#Page IDs are strings, but Perl thinks they're numbers.
$RPC::XML::FORCE_STRING_ENCODING = 1;
$RPC::XML::ENCODING = 'utf-8';

our $DEFAULT_API     = 'confluence1';
our $DEFAULT_AGENT   = "EditConfluence/$VERSION "; #trailing space tells LWP::UserAgent to prepend instead of assign
our $DEFAULT_MINOR   = 'false';
our $DEFAULT_SUMMARY = "BOT edit using $DEFAULT_AGENT";
our $DEFAULT_SPACE   = '';

our $ERROR_WARN      = 1;
our $ERROR_DIE       = 0;
our $TRACE           = 0;


################
## CONSTRUCTOR
################

sub new {
	#create new object
	my $self = shift;
    unless (ref $self) {
        $self = fields::new($self);
    }
	
	my $arg = _hash(@_);
	
	my $url = $arg->{url} or croak 'Needs URL';
	my $noconnect = $arg->{noconnect};
	
	unless ($noconnect) {
		my $username = $arg->{username} or croak 'Needs username';
		my $password = $arg->{password} or croak 'Needs password';
	}
	
	#configure RPC::XML::Client
	$self->{client} = RPC::XML::Client->new($url) or die 'Failed to create RPC::XML::Client';
	$self->client->useragent->agent($arg->{agent} // $DEFAULT_AGENT);
	
	#configure our object some more
	$self->api($arg->{api} // $DEFAULT_API);
	$self->defaultMinor($arg->{defaultMinor} // $DEFAULT_MINOR);
	$self->defaultSpace($arg->{defaultSpace} // $DEFAULT_SPACE);
	$self->defaultSummary($arg->{defaultSummary} // $DEFAULT_SUMMARY);
	$self->{specialSend} = $arg->{specialSend} if exists $arg->{specialSend};
	
	#login call
	$self->login($arg) unless $noconnect;
	
	return $self;
}


########################
## GETTERS AND SETTERS
########################

#API prefix, prepended to function call names
#ie: 'login' becomes 'confluence1.login'
sub api {
	my ($self, $api) = @_;
	$self->{api} = $api if defined $api;
	return $self->{api};
}

#Underlying RPC::XML::Client handler
#Analogous to the underlying agent in WWW::Mechanize
sub client {
	my ($self, $client) = @_;
	if (defined $client) {
		croak 'Invalid client' unless ref $client eq 'RPC::XML::Client';
		$self->{client} = $client;
	}
	return $self->{client};
}

#Mark edits as minor changes?
sub defaultMinor {
	my ($self, $defaultMinor)  = @_;
	if (defined $defaultMinor) {
		croak 'defaultMinor should be string /true|false/' unless $defaultMinor =~ /true|false/;
		$self->{defaultMinor} = $defaultMinor;
	}
	return $self->{defaultMinor};
}

#Default space to be used for page operations
sub defaultSpace {
	my ($self, $defaultSpace) = @_;
	$self->{defaultSpace} = $defaultSpace if defined $defaultSpace;
	return $self->{defaultSpace};
}

#Default edit summary, used if none is provided
sub defaultSummary {
	my ($self, $defaultSummary) = @_;
	$self->{defaultSummary} = $defaultSummary if defined $defaultSummary;
	return $self->{defaultSummary};
}

#Error string
sub errstr {
	my ($self, $errstr) = @_;
	$self->{errstr} = $errstr if defined $errstr;
	return $self->{errstr};
}

#Reset errstr
sub resetErr {
	my $self = shift;
	$self->{errstr} = undef;
}

#API session token
sub token {
	my ($self, $token) = @_;
	$self->{token} = $token if defined $token;
	return $self->{token};
}


###################
## INTERNAL CALLS
###################

sub _send {
	my $self = shift;
	my $request = shift;
	
	if (exists $self->{specialSend}) {
		return $self->{specialSend}->($request);
	} else {
		return $self->client->simple_request($request);
	}
}

#If we get an array that looks like a hash, convert it to a hashref
#If we get a hash, pass it through
#Otherwise, cry on home
sub _hash {
	my $hash;
	if (scalar @_ % 2 == 0) {
		my %h = @_;
		$hash = \%h;
	} else {
		$hash = shift;
	}
	confess 'Hash expected' unless ref $hash eq 'HASH';
	return $hash;
}

#Do we think the requested page exists on the server?
#This is clumsy, but the server throws an error if we ask for a page that doesn't exist.
sub _pageIsCached {
	my $self = shift;
	my $arg = _hash(@_);
	
	my $spaceKey  = $arg->{spaceKey}  // $self->defaultSpace // croak 'Needs spaceKey or set defaultSpace';
	my $pageTitle = $arg->{pageTitle} or croak 'Needs pageTitle';
	
	if (defined $self->{cachedPageTitles}{$spaceKey}) {
		return scalar grep { $pageTitle } @{$self->{cachedPageTitles}{$spaceKey}};
	} else {
		return 0;
	}
}

#Do we think the requested user exists on the server?
sub _userIsCached {
	my $self = shift;
	my $arg = _hash(@_);
	
	my $username = $arg->{username} or croak 'Needs username';
	
	return scalar grep { $username } @{$self->{cachedUsernames}};
}

sub _userGroupIsCached {
	my $self = shift;
	my $arg = _hash(@_);
	
	my $groupname - $arg->{groupname} or croak 'Needs groupname';
	
	return scalar grep { $groupname } @{$self->{cachedUserGroups}};
}


#####################
## DIRECT API CALLS
#####################

#Bare call to Confluence API
#Automatically prepends token to arg list when needed
#ie: $editor->call('login', 'username', 'password');
#ie: $editor->call('getPages', 'MySpaceKey');
sub call {
	my $self = shift;
	my $function = shift;
	my @args = @_;
	
	carp "Calling '$function'" if $TRACE;
	
	#calls other than login require an initial "token" param
	#TODO: do any other functions omit the token param? grep against a list?
	unshift @args, $self->token unless $function eq 'login';
	
	#build request
	RPC::XML->smart_encode(@args);
	my $request = RPC::XML::request->new("$self->{api}.$function", @args) or croak "Failed to build request for '$function'";
	my $response = $self->_send($request) or croak "Failed to send '$function' [$RPC::XML::ERROR]";
	# my $response = $self->client->simple_request("$self->{api}.$function", @args) or croak "Failed to call '$function' [$RPC::XML::ERROR]";
	
	#error responses are a hash containing 'faultCode' and 'faultString'
	if (ref $response eq 'HASH' && exists $response->{faultString}) {
		croak "Error calling '$function': $response->{faultString}";
	}
	
	return $response;
}


######################
## SESSION API CALLS
######################

sub login {
	my $self = shift;
	confess 'Not a static method' unless ref $self eq __PACKAGE__;
	
	my $arg = _hash(@_);
	my $username = $arg->{username} or croak 'Needs username';
	my $password = $arg->{password} or croak 'Needs password';
	
	$self->token($self->call('login', $username, $password));
	
	return $self->token;
}

sub logout {
	my $self = shift;
	confess 'Not a static method' unless ref $self eq __PACKAGE__;
	return $self->call('logout');
}


######################
## PAGE API CALLS
######################

sub pageExists {
	my $self = shift;
	confess 'Not a static method' unless ref $self eq __PACKAGE__;
	
	my $arg = _hash(@_);
	# my $spaceKey = $arg->{spaceKey} // $self->defaultSpace // croak 'Needs spaceKey or set defaultSpace';
	# my $pageTitle = $arg->{pageTitle} or croak 'Needs pageTitle';
	
	if ($self->_pageIsCached($arg)) {
		return 1;
	} else {
		$self->getPages($arg);
		return $self->_pageIsCached($arg);
	}
}

sub getPage {
	my $self = shift;
	confess 'Not a static method' unless ref $self eq __PACKAGE__;
	
	#TODO: support getPage(token, id)?
	my $arg = _hash(@_);
	my $spaceKey  = $arg->{spaceKey}  // $self->defaultSpace // croak 'Needs spaceKey or set defaultSpace';
	my $pageTitle = $arg->{pageTitle} or croak 'Needs pageTitle';
	
	$self->resetErr;
	unless ($self->pageExists($arg)) {
		$self->errstr("No such page '$pageTitle' in space '$spaceKey'");
		croak $self->errstr if $ERROR_DIE;
		carp $self->errstr if $ERROR_WARN;
		return undef;
	}
	
	return $self->call('getPage', $spaceKey, $pageTitle);
}

sub getPages {
	my $self = shift;
	confess 'Not a static method' unless ref $self eq __PACKAGE__;
	
	my $arg = _hash(@_);
	my $spaceKey = $arg->{spaceKey} // $self->defaultSpace // croak 'Needs spaceKey or set defaultSpace';
	
	#get and cache all pages in this space
	my $pages = $self->call('getPages', $spaceKey);
	my @titles = map { $_->{title} } @$pages;
	$self->{cachedPageTitles}{$spaceKey} = \@titles;
	return $pages || ();
}

sub editPage {
	my $self = shift;
	confess 'Not a static method' unless ref $self eq __PACKAGE__;
	
	my $arg = _hash(@_);
	my $spaceKey  = $arg->{spaceKey}  // $self->defaultSpace // croak 'Needs spaceKey or set defaultSpace';
	my $pageTitle = $arg->{pageTitle} or croak 'Needs pageTitle';
	my $content   = $arg->{content}   or croak 'Needs content';
	my $summary   = $arg->{summary}   // $self->defaultSummary;
	my $minorEdit = $arg->{minorEdit} // $self->defaultMinor;
	
	#if page doesn't exist, you should use createPage() instead
	$self->resetErr;
	unless ($self->pageExists(spaceKey => $spaceKey, pageTitle => $pageTitle)) {
		$self->errstr("Cannot edit page '$pageTitle', does not exist in space '$spaceKey'");
		croak $self->errstr if $ERROR_DIE;
		carp $self->errstr if $ERROR_WARN;
		return undef;
	}
	
	#generate page fields (mostly copied from existing page)
	my $oldPage = $self->getPage($arg) or confess 'Page lookup failed';
	my $page = {
		id       => $oldPage->{id},
		space    => $oldPage->{space},
		title    => $oldPage->{title},
		version  => $oldPage->{version},
		parentId => $oldPage->{parentId},
		content  => $content,
	};
	my $pageUpdateOptions = {
		versionComment => $summary,
		minorEdit => $minorEdit,
	};
	
	return $self->call('updatePage', $page, $pageUpdateOptions);
}

sub createPage {
	my $self = shift;
	confess 'Not a static method' unless ref $self eq __PACKAGE__;
	
	my $arg = _hash(@_);
	my $spaceKey  = $arg->{spaceKey}  // $self->defaultSpace // croak 'Needs spaceKey or set defaultSpace';
	my $pageTitle = $arg->{pageTitle} or croak 'Needs pageTitle';
	my $content   = $arg->{content}   or croak 'Needs content';
	
	#if page already exists, you should use editPage() instead
	$self->resetErr;
	if ($self->pageExists($arg)) {
		$self->errstr("Cannot create page '$pageTitle', already exists in space '$spaceKey'");
		croak $self->errstr if $ERROR_DIE;
		carp $self->errstr if $ERROR_WARN;
		return undef;
	}
	
	#generate page fields
	my $page = {
		space => $spaceKey,
		title => $pageTitle,
		content => $content,
	};
	
	#create and cache page
	my $response = call('storePage', $page);
	push($self->{cachedPageTitles}{$spaceKey}, $pageTitle);
	return $response;
}

sub editOrCreatePage {
	my $self = shift;
	confess 'Not a static method' unless ref $self eq __PACKAGE__;
	
	my $arg = _hash(@_);
	my $spaceKey  = $arg->{spaceKey}  // $self->defaultSpace // croak 'Needs spaceKey or set defaultSpace';
	my $pageTitle = $arg->{pageTitle} or croak 'Needs pageTitle';
	
	if (pageExists($arg)) {
		return $self->editPage($arg);
	} else {
		return $self->editPage($arg);
	}
}


1; #End of EditConfluence.pm
