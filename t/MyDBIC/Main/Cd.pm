package MyDBIC::Main::Cd;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ RDBOHelpers Core /);
__PACKAGE__->table('cd');
__PACKAGE__->add_columns(qw/ cdid artist title/);
__PACKAGE__->set_primary_key('cdid');
__PACKAGE__->belongs_to( 'artist' => 'MyDBIC::Main::Artist' );
__PACKAGE__->has_many(
    'cd_tracks' => 'MyDBIC::Main::CdTrackJoin',
    'cdid'
);
__PACKAGE__->many_to_many(
    'tracks' => 'cd_tracks',
    'trackid'
);

sub schema_class_prefix {'MyDBIC::Main'}

1;
