use Test::More tests => 4;

BEGIN {
	use_ok('Atlassian::EditConfluence');
	use_ok('RPC::XML');
}

is($RPC::XML::FORCE_STRING_ENCODING, 1, 'FORCE_STRING_ENCODING');
is($RPC::XML::ENCODING, 'utf-8', 'ENCODING');