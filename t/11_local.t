use Test::More;
use Test::Exception;
use File::Spec;

use sigtrap 'handler' => sub { exit 0; }, 'INT';


if (eval 'require RPC::XML::Server; 1;') {
	require t::lib::TestServer;
	
	my $pid = fork();
	if ($pid) {
		runTests();
		kill 'INT', $pid;
	} else {
		t::lib::TestServer->run();
	}
} else {
	plan skip_all => "Could not load RPC::XML::Server";
}

sub runTests {
	plan tests => 2;
	
	require_ok('Atlassian::EditConfluence');
	
	lives_ok {
		$editor = Atlassian::EditConfluence->new({
			username => 'username',
			password => 'password',
			url => 'http://localhost:9000',
			noconnect => 1
		});
	} 'connect';
}


# if (eval 'require RPC::XML::Server; 1;') {
	# my $pid = fork();
	# if ($pid) {
		# runTests();
		# diag("Sending kill\n");
		# kill 'INT', $pid;
		# done_testing();
		# diag("sent kill\n");
		# exit;
	# } else {
		# diag("server starting\n");
		# require t::lib::TestServer;
		# close STDERR;
		# close STDOUT;
		# t::lib::TestServer->run();
		# diag("server quit\n");
		# exit;
	# }
# } else {
	# plan skip_all => "Could not load RPC::XML::Server";
# }


	
	# isa_ok($editor, 'Atlassian::EditConfluence', 'type');
	
	# is($editor->api, $Atlassian::EditConfluence::DEFAULT_API, 'get api');
	# isa_ok($editor->client, 'RPC::XML::Client', 'get client');
	# is($editor->defaultSummary, $Atlassian::EditConfluence::DEFAULT_SUMMARY, 'get defaultSummary');
	# is($editor->defaultMinor, $Atlassian::EditConfluence::DEFAULT_MINOR, 'get defaultMinor');
	# is($editor->defaultSpace, '', 'get defaultSpace');
	# is($editor->errstr, undef, 'get errstr');
	# isnt($editor->token, undef, 'get token');
	
	# my $newDefaultSum = $Atlassian::EditConfluence::DEFAULT_SUMMARY . ' testsummary123';
	# $editor->defaultSummary($newDefaultSum);
	# is($editor->defaultSummary, $newDefaultSum, 'set defaultSummary');
	
	# my $newDefaultMinor = $Atlassian::EditConfluence::DEFAULT_MINOR eq 'true' ? 'false' : 'true';
	# $editor->defaultMinor($newDefaultMinor);
	# is($editor->defaultMinor, $newDefaultMinor, 'set defaultMinor');
	
	# my $newDefaultSpace = 'testspace123';
	# $editor->defaultSpace($newDefaultSpace);
	# is($editor->defaultSpace, $newDefaultSpace, 'set DefaultSpace');
	
# }

# my $FILENAME = 'credentials.txt';
# if (not -e $FILENAME) {
	# plan skip_all => "Tests irrelevant without $FILENAME";
# } else {
	# plan tests => 13;
	
	# require_ok('Atlassian::EditConfluence');
	
	# open(my $IN, '<', $FILENAME) or die "Open failed: $!";
	# chomp(my $username = readline($IN));
	# chomp(my $password = readline($IN));
	# chomp(my $url = readline($IN));
	# close($IN);
	
	# unless ($username && $password && $url) {
		# die "Invalid $FILENAME";
	# }
	
	# my $editor;
	# lives_ok {
		# $editor = Atlassian::EditConfluence->new({
			# username => $username,
			# password => $password,
			# url => $url
		# });
	# } 'connect';
	
	# isa_ok($editor, 'Atlassian::EditConfluence', 'type');
	
	# is($editor->api, $Atlassian::EditConfluence::DEFAULT_API, 'get api');
	# isa_ok($editor->client, 'RPC::XML::Client', 'get client');
	# is($editor->defaultSummary, $Atlassian::EditConfluence::DEFAULT_SUMMARY, 'get defaultSummary');
	# is($editor->defaultMinor, $Atlassian::EditConfluence::DEFAULT_MINOR, 'get defaultMinor');
	# is($editor->defaultSpace, '', 'get defaultSpace');
	# is($editor->errstr, undef, 'get errstr');
	# isnt($editor->token, undef, 'get token');
	
	# my $newDefaultSum = $Atlassian::EditConfluence::DEFAULT_SUMMARY . ' testsummary123';
	# $editor->defaultSummary($newDefaultSum);
	# is($editor->defaultSummary, $newDefaultSum, 'set defaultSummary');
	
	# my $newDefaultMinor = $Atlassian::EditConfluence::DEFAULT_MINOR eq 'true' ? 'false' : 'true';
	# $editor->defaultMinor($newDefaultMinor);
	# is($editor->defaultMinor, $newDefaultMinor, 'set defaultMinor');
	
	# my $newDefaultSpace = 'testspace123';
	# $editor->defaultSpace($newDefaultSpace);
	# is($editor->defaultSpace, $newDefaultSpace, 'set DefaultSpace');
# }