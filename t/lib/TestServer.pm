package t::lib::TestServer;

our $VERSION = 0.02;;

use strict;

use RPC::XML;
use RPC::XML::Server;

our $TOKEN = '94a08da1fecbb6e8b46990538c7b50b2';
our $USER  = 'test';
our $PASS  = 'secret';

our %spaces;

#populate test spaces
$spaces{'space1'} = {};
$spaces{'space2'} = {};

my $server = RPC::XML::Server->new(
	no_http => 1,
	fault_table => {
		badspace => [ 0 => 'Bad space: %s'   ],
		badtitle => [ 0 => 'Bad title: %s'   ],
		badtoken => [ 0 => 'Bad token: %s'   ],
		badlogin => [ 0 => 'Bad credentials' ],
	},
);

sub _addPage {
	my ($space, $title, $content) = @_;
	
	return $server->server_fault('badspace', $space) unless exists $spaces{$space};
	return $server->server_fault('badtitle', $title) if exists $spaces{$space}{$title};
	
	my $page = {
		id => '1000',
		space => $space,
		title => $title,
		version => 0,
		parentId => '100',
		content => $content,
	};
	
	$spaces{$space}{$title} = $page;
	return $page;
}

sub _editPage {
	my ($space, $title, $content) = @_;	
	
	return $server->server_fault('badspace', $space) unless exists $spaces{$space};
	return $server->server_fault('badtitle', $title) unless exists $spaces{$space}{$title};
	
	$spaces{$space}{$title}{content} = $content;
	return $spaces{$space}{$title};
}

sub getPage {
	my ($token, $space, $title) = @_;
	
	return $server->server_fault('badtoken', $token) unless $token eq $TOKEN;
	return $server->server_fault('badspace', $space) unless exists $spaces{$space};
	return $server->server_fault('badtitle', $title) unless exists $spaces{$space}{$title};
	
	return $spaces{$space}{$title};
}

sub getPages {
	my ($token, $space) = @_;
	
	return $server->server_fault('badtoken', $token) unless $token eq $TOKEN;
	return $server->server_fault('badspace', $space) unless exists $spaces{$space};
 
	my @list = map {
		my $page = $spaces{$space}{$_};
		{
			id => '1000',
			space => $space,
			parentId => '100',
			title => $_,			
		};
	} keys $spaces{$space};
	
	return \@list or die;
}

_addPage('space1', 'Cats'     , 'All about cats!'                       );
_addPage('space1', 'Dogs'     , 'A little about dogs.'                  );
_addPage('space1', 'Test page', 'I wrote a test, once; it was horrible.');
_addPage('space2', 'Rarity'   , 'There are very few pages in space2.'   );

$server->add_procedure({
	name => 'confluence1.login',
	signature => ['string string string'],
	code => sub {
		my ($user, $pass) = @_;
		return $TOKEN if $user eq $USER && $pass eq $PASS;
		return $server->server_fault('badlogin');
	},
});

$server->add_procedure({
	name => 'confluence1.logout',
	signature => ['nil string'],
	code => sub { return ''; },
});

$server->add_procedure({
	name => 'confluence1.getPages',
	signature => ['array string string'],
	code => \&getPages,
});

sub dispatch {
	my $request = shift;
	if ($request eq __PACKAGE__) { $request = shift; }
	return $server->dispatch($request);
}

1;