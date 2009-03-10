use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "IO::Easy",
	VERSION_FROM => "lib/IO/Easy.pm",
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	AUTHOR => 'Ivan Baktsheev <dot.and.thing@gmail.com>',
	PREREQ_PM => {
		'Class::Easy' => 0,
		'Encode'      => 0,
		'File::Spec'  => 0,
	}
);
