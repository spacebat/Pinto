package Pinto::Action::Remove;

# ABSTRACT: Remove one distribution from the repository

use Moose;
use MooseX::Types::Moose qw( Str );

use Pinto::Util;
use Pinto::Exceptions qw(throw_error);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Attributes

has path  => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#------------------------------------------------------------------------------

with qw( Pinto::Interface::Authorable );

#------------------------------------------------------------------------------


override execute => sub {
    my ($self) = @_;

    my $path    = $self->path();
    my $author  = $self->author();

    $path = $path =~ m{/}mx ? $path
                            : Pinto::Util::author_dir($author)->file($path)->as_foreign('Unix');

    my $where = {path => $path};
    my $dist  = $self->repos->select_distributions( $where )->single();
    throw_error "Distribution $path does not exist" if not $dist;

    $self->info(sprintf "Removing distribution $dist with %d packages", $dist->package_count());

    $self->repos->remove_distribution($dist);

    $self->add_message( Pinto::Util::removed_dist_message($dist) );

    return 1;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
