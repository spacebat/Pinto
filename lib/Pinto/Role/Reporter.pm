# ABSTRACT: Something that reports about the repository

package Pinto::Role::Reporter;

use Moose::Role;

use Pinto::Types qw(IO);

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has out => (
    is      => 'ro',
    isa     => IO,
    coerce  => 1,
    default => sub { [fileno(STDOUT), '>'] },
);

#-----------------------------------------------------------------------------

1;

__END__
