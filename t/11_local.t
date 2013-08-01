use Test::More;
use Test::Exception;
use File::Spec;

use sigtrap 'handler' => sub { exit 0; }, 'INT';

if (eval 'require RPC::XML::Server; 1;') {
	runTests();
} else {
	plan skip_all => "Could not load RPC::XML::Server";
}

sub runTests {
	require t::lib::TestServer;
	require Atlassian::EditConfluence;
	
	plan tests => 4;
	
	my $editor;
	subtest 'constructor' => sub {
		lives_ok {
			$editor = Atlassian::EditConfluence->new({
				username => $t::lib::TestServer::USER,
				password => $t::lib::TestServer::PASS,
				url => 'http://localhost:9000',
				specialSend => sub {
					t::lib::TestServer->dispatch(@_);
				}
			});
		} 'connect';
		isa_ok($editor, 'Atlassian::EditConfluence', 'type');
	};
	
	subtest 'die on fault' => sub {
		dies_ok {
			Atlassian::EditConfluence->new({
				username => $t::lib::TestServer::USER,
				password => $t::lib::TestServer::PASS . 'badpass',
				url => 'http://localhost:9000',
				specialSend => sub {
					t::lib::TestServer->dispatch(@_);
				}
			});
		};
	};
	
	subtest 'getters' => sub {	
		is($editor->api, $Atlassian::EditConfluence::DEFAULT_API, 'get api');
		isa_ok($editor->client, 'RPC::XML::Client', 'get client');
		is($editor->defaultSummary, $Atlassian::EditConfluence::DEFAULT_SUMMARY, 'get defaultSummary');
		is($editor->defaultMinor, $Atlassian::EditConfluence::DEFAULT_MINOR, 'get defaultMinor');
		is($editor->defaultSpace, '', 'get defaultSpace');
		is($editor->errstr, undef, 'get errstr');
		is($editor->token, $t::lib::TestServer::TOKEN, 'get token');
	};
	
	subtest 'setters' => sub {	
		my $newDefaultSum = $Atlassian::EditConfluence::DEFAULT_SUMMARY . ' testsummary123';
		$editor->defaultSummary($newDefaultSum);
		is($editor->defaultSummary, $newDefaultSum, 'set defaultSummary');
		
		my $newDefaultMinor = $Atlassian::EditConfluence::DEFAULT_MINOR eq 'true' ? 'false' : 'true';
		$editor->defaultMinor($newDefaultMinor);
		is($editor->defaultMinor, $newDefaultMinor, 'set defaultMinor');
		
		my $newDefaultSpace = 'testspace123';
		$editor->defaultSpace($newDefaultSpace);
		is($editor->defaultSpace, $newDefaultSpace, 'set DefaultSpace');
	};
}