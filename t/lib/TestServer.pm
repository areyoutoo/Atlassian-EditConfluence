package t::lib::TestServer;

use strict;

use RPC::XML;
use RPC::XML::Server;

my $server = RPC::XML::Server->new(
	no_http => 1,
);

$server->add_procedure({
	name => 'confluence1.login',
	signature => ['string string string'],
	code => sub { return 'token'; },
});

$server->add_procedure({
	name => 'confluence1.logout',
	signature => ['nil string'],
	code => sub { return ''; },
});

sub dispatch {
	my $request = shift;
	return $server->dispatch($request);
}

1;