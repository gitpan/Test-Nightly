#!/usr/bin/perl -w

use lib qw( ./blib/lib ../blib/lib );

use strict;
use Test::More tests => 4;
use Carp;
use Data::Dumper;
use blib;

my $report = '/tmp/passing_test_report.txt';

&cleanup;

#==================================================
# Check that module loads
#==================================================

BEGIN { use_ok( 'Test::Nightly' ) };

&cleanup;

#==================================================
# SCENARIO TWO
#	- We are only reporting on passed tests
#   - Everything is passed into new
#	- Different type of test directory ('a')
# 
#==================================================

my $nightly = Test::Nightly->new({
	base_directories 	=> ['t/data/module/'],
	run_tests			=> {
		test_directory_format	=> ['a'],
		test_report				=> 'passed',
	},
	generate_report	=> {
		report_output => $report, 
	},
});

#==================================================
# Check that test_report has been set to passed
#==================================================

ok($nightly->test_report() eq 'passed', 'test_report has been set to passed');

#==================================================
# Check that test_directory_format has been set 
# to "a" 
#==================================================

ok($nightly->test_directory_format()->[0] eq 'a', 'test_directory_format has been set to "a"');

my $file_exists = 0;
if (-e $report) {
	$file_exists = 1;
}

ok($file_exists, 'Report was generated, as expected');

&cleanup();

sub cleanup {
	
	unlink ($report);

}
