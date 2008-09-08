use Test::More tests => 29;
use strict;
use lib qw( t ../lib lib );
use Data::Dump qw( dump );
use Carp;

END { unlink('t/dbic_example.db') unless $ENV{PERL_DEBUG}; }

SKIP: {

    eval "use DBIx::Class";
    if ($@) {
        skip "DBIC required to test DBIC driver", 29;
    }
    elsif ( $DBIx::Class::VERSION < 0.08010 ) {
        skip "DBIx::Class VERSION 0.08010 or newer required", 29;
    }

    eval "use DBIx::Class::RDBOHelpers";
    if ($@) {
        skip "DBIx::Class::RDBOHelpers required for DBIC support", 29;
    }

    use_ok('MyDBIC::Form::Cd');
    use_ok('MyDBIC::Form::Artist');
    use_ok('MyDBIC::Form::Track');
    use_ok('MyDBIC::Form::CdEdition');
    use_ok('MyDBIC::Form::CdCollection');

    system("cd t/ && $^X dbic_create.pl") and die "can't create db: $!";

    ok( my $cdform     = MyDBIC::Form::Cd->new(),     "new Cd form" );
    ok( my $artistform = MyDBIC::Form::Artist->new(), "new Artist form" );
    ok( my $trackform  = MyDBIC::Form::Track->new(),  "new Track form" );
    ok( my $cdcollectionform = MyDBIC::Form::CdCollection->new(),
        "new CdCollection form" );
    ok( my $cdeditionform = MyDBIC::Form::CdEdition->new(),
        "new CdEdition form" );

    # Cd
    ok( my $cd_rels = $cdform->metadata->relationships, "cd relationships" );
    is( scalar(@$cd_rels), 2, "2 cd rels" );
    is( $cdform->metadata->relationship_info('tracks')->type,
        'many to many', 'tracks rel is a m2m' );
    ok( $cdform->metadata->is_related_field('artist'),
        "artist is related field" );
    is( $cdform->metadata->relationship_info('artist')->type,
        'foreign key', 'artist is a fk' );

    # Artist
    ok( my $artist_rels = $artistform->metadata->relationships,
        "artist relationships" );
    is( scalar(@$artist_rels),    1,             "1 artist rel" );
    is( $artist_rels->[0]->type,  "one to many", "is o2m" );
    is( $artist_rels->[0]->name,  "cds",         "name == cds" );
    is( $artist_rels->[0]->label, "Cds",         "label == Cd" );

    # Track
    ok( my $track_rels = $trackform->metadata->relationships,
        "track relationships" );
    is( scalar(@$track_rels),   1,              "1 track rel" );
    is( $track_rels->[0]->type, "many to many", "is m2m" );
    is( $track_rels->[0]->name, "cds",          "name == cds" );

    # CdEdition
    ok( my $cdedition_rels = $cdeditionform->metadata->relationships,
        "cdedition relationships" );
    is( scalar(@$cdedition_rels), 2, "2 cdedition rels" );

    # make sure interrelate fields was aborted for the cdcollection rel
    ok( $cdeditionform->field('cdid')
            ->isa('Rose::HTML::Form::Field::Integer'),
        "interrelate_fields correctly aborted"
    );

    #dump $cdeditionform;

    # CdCollection

    ok( my $cdcollection_rels = $cdcollectionform->metadata->relationships,
        "cdcollection relationships" );
    is( scalar(@$cdcollection_rels), 1, "1 cdcollection rel" );

    #dump $cdcollectionform;
}
