#!/usr/bin/perl -w

use lib qw( ./blib/lib ../blib/lib );

use strict;
use Test::More tests => 1;
use Carp;
use blib;

#==================================================
# Check that module loads
#==================================================

BEGIN { use_ok( 'Test::Nightly::Report::Template' ) };

