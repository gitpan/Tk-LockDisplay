use ExtUtils::MakeMaker;
WriteMakefile(
    NAME      => 'Tk::LockDisplay',
    DISTNAME  => "Tk-LockDisplay",
    VERSION   => '1.0',
    dist      => { COMPRESS => 'gzip', SUFFIX => 'gz'},
    ($] >= 5.005 ?
	(ABSTRACT => 'Lock X display until password entered.',
	 AUTHOR   => 'Stephen O. Lidie (sol0@Lehigh.EDU)') : ()),
);
