#!/usr/bin/perl -w

use lib qw( ./blib/lib ../blib/lib );

use strict;
use Test::More tests => 5;
use Carp;
use Data::Dumper;
use blib;

#==================================================
# Check that module loads
#==================================================

BEGIN { use_ok( 'Test::Nightly::Test' ) };

my @methods = qw(new run);

#==================================================
# Check module methods
#==================================================
can_ok('Test::Nightly::Test', @methods);

my @modules = (
	{
		directory 	=> 't/data/module/' ,
		makefile	=> 'Makefile.PL',
	},
);

my $test_extentions = Test::Nightly::Test->new({
	modules					=> \@modules,
	test_directory_format 	=> ['fake_test_folder/'],
    test_file_format      	=> ['.pl'],   
});

#==================================================
# Check that the correct folder was retrieved
#==================================================

ok($test_extentions->test_directory_format()->[0] eq 'fake_test_folder/', 'new() - The correct folder format was retrieved');

#==================================================
# Check that the correct test file format was 
# retrieved
#==================================================

ok($test_extentions->test_file_format()->[0] eq '.pl', 'new() - The correct file format was retrieved');

my $test = Test::Nightly::Test->new({
	modules	=> \@modules,
});

$test->run();

ok($test->tests()->{'t/data/module/t'}->[0]->{status} eq 'passed', 'Test that was supposed to pass, passed');


