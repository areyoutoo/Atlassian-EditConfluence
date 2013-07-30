use Test::More;
use Test::Exception;

# BEGIN {
	# use_ok('Atlassian::EditConfluence');
# }


my $FILENAME = 'credentials.txt';
if (not -e $FILENAME) {
	plan skip_all => "Tests irrelevant without $FILENAME";
} else {
	plan tests => 10;
	
	require_ok('Atlassian::EditConfluence');
	
	open(my $IN, '<', $FILENAME) or die "Open failed: $!";
	chomp(my $username = readline($IN));
	chomp(my $password = readline($IN));
	chomp(my $url = readline($IN));
	close($IN);
	
	unless ($username && $password && $url) {
		die "Invalid $FILENAME";
	}
	
	my $editor;
	lives_ok {
		$editor = Atlassian::EditConfluence->new({
			username => $username,
			password => $password,
			url => $url
		});
	} 'connect';
	
	isa_ok($editor, 'Atlassian::EditConfluence', 'type');
	
	is($editor->api, $Atlassian::EditConfluence::DEFAULT_API, 'api');
	isa_ok($editor->client, 'RPC::XML::Client', 'client');
	is($editor->defaultSummary, $Atlassian::EditConfluence::DEFAULT_SUMMARY, 'defaultSummary');
	is($editor->defaultMinor, $Atlassian::EditConfluence::DEFAULT_MINOR, 'defaultMinor');
	is($editor->defaultSpace, '', 'defaultSpace');
	is($editor->errstr, undef, 'errstr');
	isnt($editor->token, undef, 'token');
}