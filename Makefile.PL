use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Atlassian::EditConfluence',
	ABSTRACT     => 'Edit Confluence wiki pages',
	VERSION_FROM => 'lib/Atlassian/EditConfluence.pm',
	AUTHOR       => 'Robert Utter <utter.robert@gmail.com>',
	LICENSE      => 'perl',
	
	PREREQ_PM    => {
		'RPC::XML'                 => 1.56, #TODO: is an earlier version okay?
		'RPC::XML::Client'         => 1.4, #TODO: is an earlier version okay?
		'Math::Cartesian::Product' => 1.006,
	},
);