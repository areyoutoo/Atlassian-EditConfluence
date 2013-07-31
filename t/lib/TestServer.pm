package t::lib::TestServer;

use strict;

use RPC::XML;
use RPC::XML::Server;

my $server = RPC::XML::Server->new(
	port => 9000
);

$server->add_procedure({
	name => 'confluence1.login',
	signature => ['string string string'],
	code => sub { return 'token'; },
});

run() if scalar @ARGV;

sub run {
	$server->server_loop(
		signal => 'INT'
	);
	close STDOUT;
	close STDERR;
	# exit 0;
}

1;