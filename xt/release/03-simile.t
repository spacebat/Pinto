#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;

#------------------------------------------------------------------------------
note("This test requires a live internet connection to pull stuff from CPAN");
#------------------------------------------------------------------------------

# The POE-Test-Loops dist contains a mixin for POE::Kernel, but it is not
# in a file called POE/Kernel.pm.  So if we pull POE::Kernal first (via
# the main POE dist) then POE::Kernel from POE-Test-Loops should not be
# registered.

# I probably should make a proper unit test out of this.  But my wrappers
# around Module::Faker::Dist are not currently set up to let you create
# a module where the package name and file name don't match.  So for now,
# I'm going to be lazy and just use a release test with live data.

my $t = Pinto::Tester->new;
$t->run_ok(Pull => {targets => 'RCAPUTO/POE-1.354.tar.gz'});
$t->run_ok(Pull => {targets => 'RCAPUTO/POE-Test-Loops-1.351.tar.gz'});

# POE::Kernel should still be the one from the main POE dist
$t->registration_ok('RCAPUTO/POE-1.354/POE::Kernel~1.354');

# But other non-simile packages from P::T::L should be registered
$t->registration_ok('RCAPUTO/POE-Test-Loops-1.351/Operator~1.351');

#------------------------------------------------------------------------------

done_testing;

