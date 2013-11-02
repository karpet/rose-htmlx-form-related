use strict;
use warnings;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    NAME                => 'Rose::HTMLx::Form::Related',
    AUTHOR              => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM        => 'lib/Rose/HTMLx/Form/Related.pm',
    ABSTRACT_FROM       => 'lib/Rose/HTMLx/Form/Related.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Rose::HTML::Objects' => 0,
        'Rose::HTMLx::Form::Field::Boolean' => 0,
        'Rose::HTMLx::Form::Field::Autocomplete' => 0,
        'Rose::HTMLx::Form::Field::Serial' => 0.002,
        'Rose::HTMLx::Form::Field::PopUpMenuNumeric' => 0,
        'Data::Dump' => 0,
        'Scalar::Util' => 0,
        'MRO::Compat'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Rose-HTMLx-Form-Related-*' },

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl')
        : ()),

);
