#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Devgru::Monitor::TSCMS' ) || print "Bail out!\n";
}

diag( "Testing Devgru::Monitor::TSCMS $Devgru::Monitor::TSCMS::VERSION, Perl $], $^X" );
