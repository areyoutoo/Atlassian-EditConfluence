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
	
	plan tests => 13;
	
	require_ok('Atlassian::EditConfluence');
	
	my $editor;
	
	lives_ok {
		$editor = Atlassian::EditConfluence->new({
			username => 'username',
			password => 'password',
			url => 'http://localhost:9000',
			specialSend => sub {
				t::lib::TestServer->dispatch(@_);
			}
		});
	} 'connect';
	
	isa_ok($editor, 'Atlassian::EditConfluence', 'type');
	
	is($editor->api, $Atlassian::EditConfluence::DEFAULT_API, 'get api');
	isa_ok($editor->client, 'RPC::XML::Client', 'get client');
	is($editor->defaultSummary, $Atlassian::EditConfluence::DEFAULT_SUMMARY, 'get defaultSummary');
	is($editor->defaultMinor, $Atlassian::EditConfluence::DEFAULT_MINOR, 'get defaultMinor');
	is($editor->defaultSpace, '', 'get defaultSpace');
	is($editor->errstr, undef, 'get errstr');
	isnt($editor->token, undef, 'get token');
	
	my $newDefaultSum = $Atlassian::EditConfluence::DEFAULT_SUMMARY . ' testsummary123';
	$editor->defaultSummary($newDefaultSum);
	is($editor->defaultSummary, $newDefaultSum, 'set defaultSummary');
	
	my $newDefaultMinor = $Atlassian::EditConfluence::DEFAULT_MINOR eq 'true' ? 'false' : 'true';
	$editor->defaultMinor($newDefaultMinor);
	is($editor->defaultMinor, $newDefaultMinor, 'set defaultMinor');
	
	my $newDefaultSpace = 'testspace123';
	$editor->defaultSpace($newDefaultSpace);
	is($editor->defaultSpace, $newDefaultSpace, 'set DefaultSpace');
}