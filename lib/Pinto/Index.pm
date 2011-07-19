package Pinto::Index;

use Moose;
use Moose::Autobox;
use MooseX::Types::Path::Class;

use Compress::Zlib;
use Path::Class;

use Pinto::Package;

#------------------------------------------------------------------------------

has 'packages_by_name' => (
    is         => 'ro',
    isa        => 'HashRef',
    default    => sub { {} },
    init_arg   => undef,
);

has 'packages_by_file' => (
    is         => 'ro',
    isa        => 'HashRef',
    default    => sub { {} },
    init_arg   => undef,
);

has 'source' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
    required => 1,
);

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;
    $self->add_from_file($self->source());
    return $self;
}

#------------------------------------------------------------------------------


sub add_from_file  {
    my ($self, $file) = @_;

    return if not -e $file;

    my $fh = $file->openr();
    my $gz = Compress::Zlib::gzopen($fh, "rb")
        or die "Cannot open $file: $Compress::Zlib::gzerrno";

    my $inheader = 1;
    while ($gz->gzreadline($_) > 0) {
        if ($inheader) {
            $inheader = 0 if not /\S/;
            next;
        }
        chomp;
        my ($n, $v, $f) = split;
        my $package = Pinto::Package->new(name => $n, version => $v, file => $f);
        ($self->packages_by_file()->{$f} ||= [])->push($package);
        $self->packages_by_name()->put($n, $package);
    }

    return $self;
}

#------------------------------------------------------------------------------

sub write_to_file {
    my ($self, $file) = @_;

    $file = file($file) if not {eval $file->isa('Path::Class')};

    $file->dir()->mkpath();
    my $gz = Compress::Zlib::gzopen( $file->openw(), 'wb' );
    $self->_gz_write_header($gz);
    $self->_gz_write_packages($gz);
    $gz->gzclose();

    return $self;
}

#------------------------------------------------------------------------------

sub _gz_write_header {
    my ($self, $gz) = @_;

    $gz->gzwrite( <<END_PACKAGE_HEADER );
File:         02packages.details.txt
URL:          http://cpan.perl.org/modules/02packages.details.txt.gz
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   Pinto::Index $Pinto::Index::VERSION
Line-Count:   @{[ $self->package_count() ]}
Last-Updated: @{[ scalar localtime() ]}

END_PACKAGE_HEADER

    return $self;
}

#------------------------------------------------------------------------------

sub _gz_write_packages {
    my ($self, $gz) = @_;

    for my $package ( @{ $self->packages() } ) {
        $gz->gzwrite($package->to_string() . "\n");
    }

    return $self;
}

#------------------------------------------------------------------------------

sub merge {
    my ($self, @packages) = @_;

    for my $package (@packages) {
        $self->remove($package);
        $self->add($package);
    }

    return $self;
}

#------------------------------------------------------------------------------

sub add {
    my ($self, @packages) = @_;

    for my $package (@packages) {
        my $name = $package->name();
        my $file = $package->file();
        $self->packages_by_name()->put($name, $package);
        ($self->packages_by_file()->{$file} ||= [])->push($package);
    }

    return $self;
}

#------------------------------------------------------------------------------

sub remove {
    my ($self, @packages) = @_;

    for my $package (@packages) {

      my $name = $package->name();

      if (my $encumbent = $self->packages_by_name()->at($name)) {
          # Remove the file that contains the incumbent package and
          # then remove all packages that were contained in that file
          my $kin = $self->packages_by_file()->delete($encumbent->file());
          $self->packages_by_name()->delete($_) for map {$_->name} @{$kin};
      }

    }
    return $self;
}

#------------------------------------------------------------------------------

sub package_count {
    my ($self) = @_;
    return $self->packages_by_name()->keys()->length();
}

#------------------------------------------------------------------------------

sub packages {
    my ($self) = @_;
    return $self->packages_by_name()->values();
}

#------------------------------------------------------------------------------

sub files {
    my ($self) = @_;
    return $self->packages_by_file()->keys();
}

#------------------------------------------------------------------------------

sub validate {
    my ($self) = @_;

    for my $package ( $self->packages_by_file()->values()->map( sub {@{$_[0]}} )->flatten() ) {
      $self->packages_by_name->exists($package->name()) or die "Shit!";
    }

    for my $package ( $self->packages_by_name()->values()->flatten() ) {
      $self->packages_by_file->exists($package->file()) or die 'Shit!';
    }
}

#------------------------------------------------------------------------------


1;
