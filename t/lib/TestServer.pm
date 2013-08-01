package t::lib::TestServer;

use strict;

use RPC::XML;
use RPC::XML::Server;

our $TOKEN = '94a08da1fecbb6e8b46990538c7b50b2';
our $USER  = 'test';
our $PASS  = 'secret';

my $server = RPC::XML::Server->new(
	no_http => 1,
);

$server->add_procedure({
	name => 'confluence1.login',
	signature => ['string string string'],
	code => sub {
		my ($user, $pass) = @_;
		return $TOKEN if $user eq $USER && $pass eq $PASS;
		return '';
	},
});

$server->add_procedure({
	name => 'confluence1.logout',
	signature => ['nil string'],
	code => sub { return ''; },
});

sub dispatch {
	my $request = shift;
	if ($request eq __PACKAGE__) { $request = shift; }
	return $server->dispatch($request);
}

1;