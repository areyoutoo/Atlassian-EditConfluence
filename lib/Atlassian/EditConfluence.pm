package Atlassian::EditConfluence;

=head1 NAME

Atlassian::EditConfluence - Edit Confluence wikis in Perl!

=head1 SYNOPSIS

	use Atlassian::EditConfluence;
	
	my $editor = Atlassian::EditConfluence->new(
		url => 'https://your.wiki.url/rpc/xmlrpc',
		username => 'user123',
		password => 'my secret password',
	);
	
	$editor->editOrCreatePage(
		spaceKey => 'Department12',
		pageTitle => 'Sandbox',
		content => 'It works!',
	);

=cut

our $VERSION = 0.02_01;


############
## IMPORTS
############

use strict;
use Carp;

use RPC::XML;
use RPC::XML::Client;

use Scalar::Util qw(blessed);

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

our $ERROR_DIE       = 0;
our $ERROR_WARN      = 1;
our $FAULT_DIE       = 1;
our $FAULT_WARN      = 1;
our $TRACE           = 0;


=head1 METHODS

Unless otherwise specified, API call methods accept a hash or hashref argument.

C<call> is probably the only method that accepts an array of arguments, 
representing the ordered arguments for a direct API call.

Getters need no argument, and become setters if an argument is passed.

=cut

################
## CONSTRUCTOR
################


=head2 new(HASH)

Main arguments:

=over 4

=item * B<username>: API username

=item * B<password>: API password

=item * B<url>: API URL, such as C<'http://your.wiki.domain/rpc/xmlrpc'>

=back


Optional arguments:

=over 4

=item * B<noconnect>: If true, skip login during constructor. You 
can call it manually, later, or provide your own session token.

=item * B<agent>: User-agent string for L<RPC::XML::Client>'s underlying L<LWP::UserAgent> object. Note that LWP prefers an agent string which ends with a space. Defaults to C<$DEFAULT_AGENT> if not provided.

You can also specify C<defaultMinor>, C<defaultSpace> and C<defaultSummary> at this time by passing values for those keys.

=back

=cut

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

=head2 GETTERS AND SETTERS

=head3 api

=over 4

Gets or sets the API version prefix. Default is C<'confluence1'>.

=back

=cut

#API prefix, prepended to function call names
#ie: 'login' becomes 'confluence1.login'
sub api {
	my ($self, $api) = @_;
	$self->{api} = $api if defined $api;
	return $self->{api};
}

=head3 client

=over 4

Allows access to the underlying L<RPC::XML::Client> object. If you're using 
this module, it's probably so that you I<don't> have to work at that level of 
detail.

=back

=cut

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

=head3 defaultMinor

=over 4

Mark edits as minor? Should be C<'true'> or C<'false'>. Defaults to C<'false'>.

=back

=cut

#Mark edits as minor changes?
sub defaultMinor {
	my ($self, $defaultMinor)  = @_;
	if (defined $defaultMinor) {
		croak 'defaultMinor should be string /true|false/' unless $defaultMinor =~ /true|false/;
		$self->{defaultMinor} = $defaultMinor;
	}
	return $self->{defaultMinor};
}

=head3 defaultSpace

=over 4

Specify a C<defaultSpace> if you want to skip specifying one on every API 
call. Will be used in place of C<spaceKey> arguments as needed. Defaults to 
C<''>.

=back

=cut

#Default space to be used for page operations
sub defaultSpace {
	my ($self, $defaultSpace) = @_;
	$self->{defaultSpace} = $defaultSpace if defined $defaultSpace;
	return $self->{defaultSpace};
}

=head3 defaultSummary

=over 4

Automatically applied to edits when no other change summary is provided. 
Defaults to C<$DEFAULT_SUMMARY>.

=back

=cut

#Default edit summary, used if none is provided
sub defaultSummary {
	my ($self, $defaultSummary) = @_;
	$self->{defaultSummary} = $defaultSummary if defined $defaultSummary;
	return $self->{defaultSummary};
}

=head3 errstr

=over 4

Will be set each time an API call encounters a client error or server fault.

=back

=cut

#Error string
sub errstr {
	my ($self, $errstr) = @_;
	$self->{errstr} = $errstr if defined $errstr;
	return $self->{errstr};
}

#Reset errstr
sub _resetErr {
	my $self = shift;
	$self->{errstr} = undef;
}

=head3 token

=over 4

Get or set the API auth token. Could be used to provide another bot with our 
login session, or use another pre-authed session.

Usually, you'll want to set this by calling C<login>.

=back

=cut

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
		return $self->{specialSend}->($request)->value;
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

=head2 call(function, LIST)

=over 4

Direct API call. Used internally for all calls. You can use it to access 
functions not yet implemented in this client.

The first argument is the name of the function to call. All other arguments 
are arguments to the function. You do not need to provide the I<token> 
argument that is expected by most functions. It will be prepended 
automatically.

This will return whatever we get back from the server, usually a hash. If 
C<$FAULT_DIE> or C<$FAULT_WARN> are true, will automatically detect faults 
and react accordingly.

=back

=cut

#Bare call to Confluence API
#Automatically prepends token to arg list when needed
#ie: $editor->call('login', 'username', 'password');
#ie: $editor->call('getPages', 'MySpaceKey');
sub call {
	my $self = shift;
	my $function = shift;
	my @args = @_;
	
	carp "Calling '$function'" if $TRACE;
	
	#encode args
	# @args = RPC::XML->smart_encode(@args);
	
	#calls other than login require an initial "token" param
	#TODO: do any other functions omit the token param? grep against a list?
	unshift @args, $self->token unless $function eq 'login';

	#build and send request
	my $request = RPC::XML::request->new("$self->{api}.$function", @args) or croak "Failed to build request for '$function'";
	my $response = $self->_send($request) or croak "Failed to send '$function' [$RPC::XML::ERROR]";
	
	#convert RPC::XML::response values back to Perl
	if (blessed($response) && $response->isa('RPC::XML::datatype')) {
		$response = $response->value();
	}
	
	#error responses are a hash containing 'faultCode' and 'faultString'
	if (ref $response eq 'HASH' && exists $response->{faultString}) {
		$self->errstr("Fault calling '$function': $response->{faultString}");
		croak $self->errstr if $FAULT_DIE;
		carp $self->errstr if $FAULT_WARN;
	}
	
	return $response;
}


######################
## SESSION API CALLS
######################

=head2 SESSION CALLS

=head3 login(username, password)

=over 4

Attempts to login. Automatically called by the constructor unless otherwise 
requested.

=back

=cut

sub login {
	my $self = shift;
	confess 'Not a static method' unless ref $self eq __PACKAGE__;
	
	my $arg = _hash(@_);
	my $username = $arg->{username} or croak 'Needs username';
	my $password = $arg->{password} or croak 'Needs password';
	
	$self->token($self->call('login', $username, $password));
	
	unless ($self->token) {
		$self->errstr("Failed login (bad credentials?)");
		croak $self->errstr if $ERROR_DIE || $FAULT_DIE;
		carp $self->errstr if $ERROR_WARN || $FAULT_WARN;
	}
	
	return $self->token;
}

=head3 logout

=over 4

Ends your session.

=back

=cut

sub logout {
	my $self = shift;
	confess 'Not a static method' unless ref $self eq __PACKAGE__;
	return $self->call('logout');
}


######################
## PAGE API CALLS
######################

=head2 PAGE CALLS

=head3 pageExists

=over 4

Needs a spaceKey and pageTitle. Checks if a page exists.

Returns non-zero if the page exists.

=back

=cut

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

=head3 getPage

=over 4

Wrapper for C<getPage(token,space,page)>. Needs spaceKey and pageTitle.

Attempts to return the page from the server. If no such page exists, it will 
either die or return undef depending on C<$ERROR_DIE>.

=back

=cut

sub getPage {
	my $self = shift;
	confess 'Not a static method' unless ref $self eq __PACKAGE__;
	
	#TODO: support getPage(token, id)?
	my $arg = _hash(@_);
	my $spaceKey  = $arg->{spaceKey}  // $self->defaultSpace // croak 'Needs spaceKey or set defaultSpace';
	my $pageTitle = $arg->{pageTitle} or croak 'Needs pageTitle';
	
	$self->_resetErr;
	unless ($self->pageExists($arg)) {
		$self->errstr("No such page '$pageTitle' in space '$spaceKey'");
		croak $self->errstr if $ERROR_DIE;
		carp $self->errstr if $ERROR_WARN;
		return undef;
	}
	
	return $self->call('getPage', $spaceKey, $pageTitle);
}

=head3 getPages

=over 4

Wrapper for C<getPage(token,space)>. Needs spaceKey.

Returns PageSummary hashes for each page in the given space. If no such space 
exists, it will error out.

=back

=cut

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

=head3 editPage

=over 4

Needs spaceKey, pageTitle, content. Accepts optional parameters summary, 
minorEdit.

Attempts to edit an existing page.

Returns the new Page hash on success. If the page doesn't exist, returns 
undef or dies depending on C<$ERROR_DIE>.

=back

=cut

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
	$self->_resetErr;
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

=head3 createPage

=over 4

Needs spaceKey, pageTitle, content.

Attempts to create a new page.

Returns the new Page hash on success. If the page already exists, returns 
undef or dies depending on C<$ERROR_DIE>.

=back

=cut

sub createPage {
	my $self = shift;
	confess 'Not a static method' unless ref $self eq __PACKAGE__;
	
	my $arg = _hash(@_);
	my $spaceKey  = $arg->{spaceKey}  // $self->defaultSpace // croak 'Needs spaceKey or set defaultSpace';
	my $pageTitle = $arg->{pageTitle} or croak 'Needs pageTitle';
	my $content   = $arg->{content}   or croak 'Needs content';
	
	#if page already exists, you should use editPage() instead
	$self->_resetErr;
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

=head3 editOrCreatePage

=over 4

If page exists, calls C<editPage>; if not, calls C<createPage>. Passes through
arguments unchanged.

=back

=cut

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
