#!/usr/bin/perl -w

use lib qw( ./blib/lib ../blib/lib );

use strict;
use Test::More tests => 7;
use Carp;
use Data::Dumper;
use blib;

#==================================================
# Check that module loads
#==================================================

BEGIN { use_ok( 'Test::Nightly' ) };

#==================================================
# Check module methods
#==================================================

my @methods = qw(new run_tests generate_report);
can_ok('Test::Nightly', @methods);

my $no_args = Test::Nightly->new();

#==================================================
# Check correct error message is added when there 
# is no base_directories supplied
#==================================================

like($no_args->errors()->[0], qr/Test::Nightly::new\(\) - \"base_directories\" must be supplied/, 'new() - errors() has the correct error when no base_directories are supplied');

my $diff_make = Test::Nightly->new({base_directories => ['t/data/module/'], makefile_names => ['DiffMake01.PL', 'DiffMake02.PL']});

#==================================================
# Check DiffMake01.PL is found
#==================================================
ok($diff_make->modules->[0]->{makefile} eq 'DiffMake01.PL', 'new() - Found DiffMake01.PL');

#==================================================
# Check DiffMake02.PL is found
#==================================================
ok($diff_make->modules->[1]->{makefile} eq 'DiffMake02.PL', 'new() - Found DiffMake02.PL');

my $nightly = Test::Nightly->new({base_directories => ['t/data/module/']});

#==================================================
# Check Makefile.PL is found
#==================================================

ok($nightly->modules->[0]->{makefile} eq 'Makefile.PL', 'new() - Found Makefile.PL');

#==================================================
# Check correct module path is found
#==================================================

ok($nightly->modules->[0]->{directory} eq 't/data/module/', 'new() - Found correct module path');

