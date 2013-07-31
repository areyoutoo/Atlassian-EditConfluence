use Test::More tests => 9;
use Test::Exception;

BEGIN {
	use_ok('Atlassian::EditConfluence');
}

#Bunch of bad constructor calls
dies_ok {
	Atlassian::EditConfluence->new();
} 'constructor empty';

dies_ok {
	Atlassian::EditConfluence->new(
		username => 'foo'
	);
} 'constructor username';

dies_ok {
	Atlassian::EditConfluence->new(
		url => 'http://google.com'
	);
} 'constructor url';

dies_ok {
	Atlassian::EditConfluence->new(
		password => 'secret'
	);
} 'constructor password';

dies_ok {
	Atlassian::EditConfluence->new(
		username => 'foo',
		url => 'http://google.com'
	)
} 'constructor username-url';

dies_ok {
	Atlassian::EditConfluence->new(
		password => 'foo',
		url => 'http://google.com'
	);
} 'constructor password-url';

dies_ok {
	Atlassian::EditConfluence->new(
		username => 'foo',
		password => 'secret'
	);
} 'constructor username-password';

dies_ok {
	Atlassian::EditConfluence->new(
		'http://google.com',
		'foo',
		'secret',
	);
} 'constructor odd args';

#TODO: set up testing with a local RPC server?
# lives_ok {
	# Atlassian::EditConfluence->new(
		# username => 'foo',
		# password => 'secret',
		# url => 'http://google.com'
	# );
# }