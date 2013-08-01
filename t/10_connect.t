use Test::More;
use Test::Exception;


my $FILENAME = 'credentials.txt';
if (not -e $FILENAME) {
	plan skip_all => "Tests irrelevant without $FILENAME";
} else {
	plan tests => 3;
	
	require Atlassian::EditConfluence;
	
	open(my $IN, '<', $FILENAME) or die "Open failed: $!";
	chomp(my $username = readline($IN));
	chomp(my $password = readline($IN));
	chomp(my $url = readline($IN));
	close($IN);
	
	unless ($username && $password && $url) {
		die "Invalid $FILENAME";
	}
	
	my $editor;
	subtest 'constructor' => sub {
		lives_ok {
			$editor = Atlassian::EditConfluence->new({
				username => $username,
				password => $password,
				url => $url
			});
		} 'connect';
		
		isa_ok($editor, 'Atlassian::EditConfluence', 'type');
	};
	
	subtest 'getters' => sub {
		is($editor->api, $Atlassian::EditConfluence::DEFAULT_API, 'get api');
		isa_ok($editor->client, 'RPC::XML::Client', 'get client');
		is($editor->defaultSummary, $Atlassian::EditConfluence::DEFAULT_SUMMARY, 'get defaultSummary');
		is($editor->defaultMinor, $Atlassian::EditConfluence::DEFAULT_MINOR, 'get defaultMinor');
		is($editor->defaultSpace, '', 'get defaultSpace');
		is($editor->errstr, undef, 'get errstr');
		isnt($editor->token, undef, 'get token');
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