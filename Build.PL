use Module::Build;

my $build = Module::Build->new(
	module_name       => 'Atlassian::EditConfluence',
	dist_abstract     => 'Edit Confluence wiki pages',
	dist_version_from => 'lib/Atlassian/EditConfluence.pm',
	dist_author       => 'Robert Utter <utter.robert@gmail.com>',
	license           => 'perl',
	
	requires => {
		'RPC::XML'         => 1.56, #TODO: is an earlier version okay?
		'RPC::XML::Client' => 1.4, #TODO: is an earlier version okay?
		'Carp'             => 0,
		'fields'           => 0,
		'strict'           => 0,
	},
	
	test_requires => {
		'Test::More'      => 0.98, #TODO: is an earlier version okay?
		'Test::Exception' => 0.31, #TODO: is an earlier version okay?
	},
);

$build->create_build_script;