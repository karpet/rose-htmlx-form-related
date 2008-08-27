package Rose::HTMLx::Form::Related;

use warnings;
use strict;

use base qw( Rose::HTML::Form );
use Carp;

use Rose::HTMLx::Form::Related::Metadata;
use Rose::HTMLx::Form::Field::Boolean;
use Rose::HTMLx::Form::Field::Autocomplete;
use Rose::HTML::Form::Field::PopUpMenu;

__PACKAGE__->field_type_class(
    boolean => 'Rose::HTMLx::Form::Field::Boolean' );
__PACKAGE__->field_type_class(
    autocomplete => 'Rose::HTMLx::Form::Field::Autocomplete' );

use Rose::Object::MakeMethods::Generic (
    'scalar --get_set_init' => [qw( metadata metadata_class app_class )],

);

our $VERSION = '0.06';

=head1 NAME

Rose::HTMLx::Form::Related - RHTMLO forms, living together

=head1 SYNOPSIS

 package MyForm;
 use strict;
 use parent 'Rose::HTMLx::Form::Related';
 1;

=head1 DESCRIPTION

Rose::HTMLx::Form::Related is a subclass of Rose::HTML::Form.
Rose::HTMLx::Form::Related can interrogate the relationships
between ORM classes and the Forms that represent them,
and use that data to tie multiple Rose::HTMLx::Form::Related
classes together.

There are some additional convenience methods provided, as well
as the addition to two more field types (B<boolean> and B<autocomplete>)
not part of the standard Rose::HTML::Form installation.

=head1 METHODS

=cut

=head2 init

Overrides base method to call interrelate_fields() if 
metadata->show_related_fields() is true.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    for my $field ( $self->fields ) {
        $field->xhtml_error_separator('');    # let CSS decide space
    }
    $self->interrelate_fields if $self->metadata->show_related_fields;
}

=head2 init_metadata

Creates and returns a Rose::HTMLx::Form::Related::Metadata object.
This method will not be called if a metadata object is passed in new().

=cut

sub init_metadata {
    croak "must define init_metadata() or pass Metadata object in new()";
}

=head2 init_metadata_class

Returns name of the metadata class. 
Default is 'Rose::HTMLx::Form::Related::Metadata'.

=cut

sub init_metadata_class {
    return 'Rose::HTMLx::Form::Related::Metadata';
}

=head2 init_app_class

Returns name of class whose instances are stored in app().

Default is the emptry string.

=cut

sub init_app_class {''}

=head2 object_class

Shortcut to metadata->object_class.

=cut

sub object_class {
    shift->metadata->object_class;
}

=head2 hidden_to_text_field( I<hidden_field_object> )

Returns a Text field based on I<hidden_field_object>.

=cut

sub hidden_to_text_field {
    my $self = shift;
    my $hidden = shift or croak "need Hidden Field object";
    unless ( ref $hidden && $hidden->isa('Rose::HTML::Form::Field::Hidden') )
    {
        croak "$hidden is not a Rose::HTML::Form::Field::Hidden object";
    }
    my @attr = ( size => 12 );
    for my $attr (qw( name label class required )) {
        push( @attr, $attr, $hidden->$attr );
    }
    return Rose::HTML::Form::Field::Text->new(@attr);
}

=head2 field_names_by_rank

Returns array ref of field names sorted numerically by their rank attribute.

=cut

sub field_names_by_rank {
    my $self = shift;
    my @new = map { $_->name }
        sort { $a->rank <=> $b->rank } $self->fields;
    return [@new];
}

=head2 interrelate_fields( [ I<N> ] )

Called by build_form() before passing to the RHTMLO (SUPER) build_form()
method.

interrelate_fields() will convert fields that return true from
metadata->related_field() to menu or autocomplete
type fields based on foreign key metadata from metadata->object_class().

In other words, interrelate_fields() will convert your many-to-one
foreign-key relationships into HTML fields that help
enforce the relationship.

The I<N> argument is the maximum number of values to consider before
creating an autocomplete field instead of a menu field. The default is
50, which is a reasonable number of options in a HTML menu.

=cut

my %count_cache;    # memoize to reduce db trips

sub interrelate_fields {
    my $self = shift;
    my $max  = shift;
    if ( !defined $max ) {
        $max = 50;
    }

    for my $field ( @{ $self->metadata->related_field_names } ) {
        my $rel_info = $self->metadata->related_field($field) or next;
        my $count = $count_cache{ $rel_info->foreign_class }
            || $self->get_objects_count(
            object_class => $rel_info->foreign_class );

        # defer $count == undef, as with DBIC deploy()
        # TODO someway to re-try later??
        next unless defined $count;

        $count_cache{ $rel_info->foreign_class } = $count;

        if ( $count > $max ) {
            $self->_convert_field_to_autocomplete( $field, $rel_info );
        }
        else {
            $self->_convert_field_to_menu( $field, $rel_info );
        }
    }
}

=head2 get_objects_count( object_class => I<class_name> )

Returns an integer reflecting the number of objects
available for iterrelate_fields().

The default is C<100> which is useless. You should override this method
in your subclass to actually query the db. All counts are memoized
internally so get_objects_count() will only ever be called
once per I<class_name>.

=cut

sub get_objects_count {100}

=head2 get_objects( object_class => I<foreign_class_name> )

Returns an array ref of objects of type I<foreign_class_name>. The
array ref is used by interrelate_fields() to auto-populate
popup menus.

The default is to return an empty array ref. Override
in your subclass to do something more meaningful.

Note that get_objects() will be called every time a new
Form object is created, so consider caching your Form
objects and just calling reset() between uses.

=cut

sub get_objects { [] }

sub _convert_field_to_menu {
    my $self       = shift;
    my $field_name = shift;
    my $rel_info   = shift;

    my $field = $self->field($field_name);
    return if $field->isa('Rose::HTML::Form::Field::Hidden');
    return if defined $field->type and $field->type eq 'hidden';

    my $fk = $rel_info->foreign_column;
    my $to_show
        = $self->metadata->show_related_field_using( $rel_info->foreign_class,
        $field_name );

    return if !defined $to_show;    

    my $all_values_hash = {
        map { $_->$fk => $_->$to_show } @{
            $self->get_objects( object_class => $rel_info->foreign_class )
            }
    };

    my $menu = Rose::HTML::Form::Field::PopUpMenu->new(
        id       => $field->id,
        type     => 'menu',
        class    => $field->class,
        label    => $field->label,
        tabindex => $field->tabindex,
        rank     => $field->rank,
        options  => [
            sort { $all_values_hash->{$a} cmp $all_values_hash->{$b} }
                keys %$all_values_hash
        ],
        labels => $all_values_hash,
    );

    # must delete first since field() will return cached $field
    # if it already has been added.
    $self->delete_field($field);
    $self->field( $field_name => $menu );
}

sub _convert_field_to_autocomplete {
    my $self       = shift;
    my $field_name = shift;
    my $rel_info   = shift;
    my $field      = $self->field($field_name);
    return if $field->isa('Rose::HTML::Form::Field::Hidden');
    return if defined $field->type and $field->type eq 'hidden';

    #dump $meta;
    my $app = $self->app || $self->app_class
        or croak "app() or app_class() required for autocomplete";
    unless ( $app->can('uri_for') ) {
        croak "app $app does not implement a uri_for() method";
    }

    my $to_show
        = $self->metadata->show_related_field_using( $rel_info->foreign_class,
        $field_name );

    return if !defined $to_show;

    my $ac = Rose::HTMLx::Form::Field::Autocomplete->new(
        id           => $field->id,
        type         => 'autocomplete',
        class        => $field->class,
        label        => $field->label,
        tabindex     => $field->tabindex,
        rank         => $field->rank,
        size         => $field->size,
        maxlength    => $field->maxlength,
        autocomplete => $app->uri_for(
            '/' . $rel_info->controller->path_prefix,
            'autocomplete'
        ),
        limit => 30,
    );

    # must delete first since field() will return cached $field
    # if it already has been added.
    $self->delete_field($field);
    $self->field( $field_name => $ac );

}

=head2 init_with_object

Overrides base method to always return the Form object that called
the method.

=cut

sub init_with_object {
    my $self = shift;
    my $ret  = $self->SUPER::init_with_object(@_);
    return $self;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-htmlx-form-related at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rose-HTMLx-Form-Related>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rose::HTMLx::Form::Related

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rose-HTMLx-Form-Related>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rose-HTMLx-Form-Related>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-HTMLx-Form-Related>

=item * Search CPAN

L<http://search.cpan.org/dist/Rose-HTMLx-Form-Related>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
