#!/usr/local/bin/perl -w
use Tk;
use Tk::LockDisplay;
use subs qw/check_pw/;
use strict;

my $mw = MainWindow->new;
my $ld = $mw->LockDisplay(-authenticate => \&check_pw, -debug => 1);

$mw->Button(qw/-text Lock -command/ => sub{$ld->Lock})->grid;
$mw->Button(qw/-text Exit -command/ => \&exit)->grid;

MainLoop;

sub check_pw {
    my($user, $pw) = @_;
    return 1;			# test always returns true (-:
} # end check_pw
