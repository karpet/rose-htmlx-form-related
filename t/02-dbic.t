use Test::More tests => 20;
use strict;
use lib qw( t ../lib lib );
use Data::Dump qw( dump );
use Carp;

END { unlink('t/dbic_example.db') unless $ENV{PERL_DEBUG}; }

SKIP: {

    eval "use DBIx::Class";
    if ($@) {
        skip "DBIC required to test DBIC driver", 20;
    }
    elsif ( $DBIx::Class::VERSION < 0.08010 ) {
        croak "DBIx::Class VERSION 0.08010 or newer required";
    }

    eval "use DBIx::Class::RDBOHelpers";
    if ($@) {
        skip "DBIx::Class::RDBOHelpers required for DBIC support", 20;
    }

    use_ok('MyDBIC::Form::Cd');
    use_ok('MyDBIC::Form::Artist');
    use_ok('MyDBIC::Form::Track');

    system("cd t/ && $^X dbic_create.pl") and die "can't create db: $!";

    ok( my $cdform     = MyDBIC::Form::Cd->new(),     "new Cd form" );
    ok( my $artistform = MyDBIC::Form::Artist->new(), "new Artist form" );
    ok( my $trackform  = MyDBIC::Form::Track->new(),  "new Track form" );

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
}
