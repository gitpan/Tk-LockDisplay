
package Tk::LockDisplay;

# Quick and dirty xlock-like dialog that requires authentication before unlocking the display.
#
# Stephen.O.Lidie@Lehigh.EDU, Lehigh University Computing Center.  98/08/12
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.

use 5.005;
use Carp;
use Tk::Toplevel;
use strict;
use base qw/Tk::Toplevel/;
Construct Tk::Widget 'LockDisplay';

sub Lock {

    # Realize the dialog, start the screensaver and snooze timer events, clear the password entry, save the current focus and
    # grab and set ours, raise the dialog and wait for the password, release our grab, clear timers, hide the dialog and restore
    # the original focus and grab.  Whew.

    my($self) = @_;
    
    $self->deiconify;
    $self->waitVisibility;
    $self->{mid} = $self->repeat($self->{Configure}{-velocity} => [$self => 'mesmerize']);
    $self->{tid} = $self->after($self->{Configure}{-hide} * 1000  => [$self => 'snooze']);
    $self->{e}->delete(0 => 'end');
    my $old_focus = $self->focusSave;
    my $old_grab  = $self->grabSave;
    $self->{e}->focus;
    $self->grab(-global);
    $self->raise;
    $self->waitVariable(\$self->{unlock});
    $self->grabRelease;
    $self->afterCancel($self->{tid});
    $self->afterCancel($self->{mid});
    $self->withdraw;
    &$old_focus;
    &$old_grab;

} # end Lock

sub Populate {

    # LockDisplay constructor.

    my($cw, $args) = @_;

    die "Can't get user name." if not my $user = getlogin;
    $cw->{user} = $user;
    $cw->{-authenticate} = delete $args->{-authenticate};
    die "-authenticate callback is improper or missing." unless ref($cw->{-authenticate}) eq 'CODE';
    $cw->{-debug} = delete $args->{-debug};
    $cw->{-debug} ||= 0;
    $cw->SUPER::Populate($args);
    
    $cw->withdraw;
    $cw->protocol('WM_DELETE_WINDOW' => sub {});
    $cw->transient;
    $cw->overrideredirect(1);

    # Mesmerizer constants.

    my(@points) = ( [20,20, 6, 9], [580,380,-3, -5] ); # initial end points of the line
    $cw->{points} = \@points;

    # 64 color constants I extracted from my special "continuous spectra" file containing 1000 data points.

    my(@colors) = (qw/
	       ffff00000000 ffff13f80000 ffff2b020000 ffff420c0000 ffff59160000 ffff70200000 ffff872a0000 ffff9e350000
	       ffffb53f0000 ffffcc490000 ffffe3530000 fffffa5d0000 ee97ffff0000 d78cffff0000 c082ffff0000 a978ffff0000
	       926effff0000 7b64ffff0000 645affff0000 4d50ffff0000 3645ffff0000 1f3bffff0000 0831ffff0000 0000ffff0ed9
	       0000ffff25e3 0000ffff3ced 0000ffff53f7 0000ffff6b02 0000ffff820c 0000ffff9916 0000ffffb020 0000ffffc72a
	       0000ffffde34 0000fffff53f 0000f3b5ffff 0000dcabffff 0000c5a1ffff 0000ae97ffff 0000978dffff 00008083ffff
	       00006978ffff 0000526effff 00003b64ffff 0000245affff 00000d50ffff 09ba0000ffff 20c40000ffff 37cf0000ffff
	       4ed90000ffff 65e30000ffff 7ced0000ffff 93f70000ffff ab010000ffff c20c0000ffff d9160000ffff f0200000ffff
	       ffff0000f8d4 ffff0000e1ca ffff0000cac0 ffff0000b3b6 ffff00009cab ffff000085a1 ffff00006e97 ffff0000578d
	       /);
    $cw->{colors} = \@colors;

    # Miscellaneous constants

    my $v = '1.0';
    my($w, $h) = ($cw->screenwidth, $cw->screenheight);
    $cw->{w} = $w;
    $cw->{h} = $h;
    my $ti = "tklock $v";
    my $max_lines = 80;
    $cw->{max_lines} = $max_lines;
    my $line_count = 0;
    $cw->{line_count} = $line_count;

    # The canvas et.al.

    my $canvas = $cw->Canvas(-width => $w, -height => $h)->grid;
    $cw->{canvas} = $canvas;
    my $fn = [qw/roman -30 italic bold/];
    my $pw;
    $cw->{pw} = \$pw;
    my $e = $canvas->Entry(-textvariable => \$pw, -show => '*');
    $cw->{e} = $e;
    my $my = $canvas->fontMeasure($fn, 'O');
    $cw->{my} = $my;
    $canvas->createText($w/2, $h/2 - 2*$my, -text => $ti, -font => $fn, -fill => 'orange');
    $canvas->createWindow($w/2, $h/2, -window => $e);

    $cw->ConfigSpecs(
		     -background => [$canvas, qw/background Background black/],
		     -velocity   => [qw/PASSIVE velocity Velocity 10/],
		     -hide       => [qw/PASSIVE hide Hide 10/],
		     -mesmerize  => [qw/PASSIVE mesmerize Mesmerize lines/],
		     );

    $cw->{tid} = undef;		# timer ID
    $cw->{mid} = undef;		# mesmerizer ID
    $cw->{unlock} = 1;		# unlock flag

    $cw->bind('<Motion>'   => [\&awake, $cw]);
    $cw->bind('<Any-Key>'  => [\&awake, $cw]);
    $cw->bind('<Double-1>' => [$cw => 'unlock']) if $cw->{-debug};

} # end Populate

# Private methods.

sub awake {

    # Make title and password entry visible by moving them from hyperspace to a visible portion of the canvas.

    my($subwidget, $self) = @_;

    my $canvas = $self->{canvas};
    $canvas->afterCancel($self->{tid});
    my($w, $h, $my) = ($self->{w}, $self->{h}, $self->{my});
    $canvas->coords(1, $w/2, $h/2 - 2*$my);
    $canvas->coords(2, $w/2, $h/2);
    $self->{tid} = $canvas->after($self->{Configure}{-hide} * 1000 => [$self => 'snooze']);
    
    if (ref($subwidget) eq 'Tk::Entry') {
	if ($Tk::event->K eq 'Return') {
	    return unless ${$self->{pw}};
	    if (&{$self->{-authenticate}}($self->{user}, ${$self->{pw}})) {
	        $self->unlock;
	    } else {
		$self->{e}->delete(0 => 'end');
		$self->bell;
	    }
        } # ifend <Return>
    } # ifend Entry widget

} # end awake

sub mesmerize {

    # Animate mesmerizer.  Reflect two points (the line's endpoints) around the confines of the canvas and draw a line between
    # them.  Lines are assigned a color and a tag - the tag tells us on which iteration the line should be deleted.
    #
    # Now we handle other screen savers, as well as user code.

    my($self) = @_;

    my $canvas = $self->{canvas};
    my $mez = $self->{Configure}{-mesmerize};

    if (ref($mez) eq 'CODE') {	# user specified mesmerizing routine
        &$mez($canvas);
    } elsif ($mez eq 'lines') {
	my($line_count, $max_lines) = ($self->{line_count}, $self->{max_lines});
	my($h, $w) = ($self->{h}, $self->{w});
	my $tag = 'l' . ($line_count - $max_lines);
	$canvas->delete($tag);
	my(@points) = @{$self->{points}};
	foreach my $point (@points) {
	    my($x0, $y0) = ($point->[0], $point->[1]);
	    my($vx, $vy) = ($point->[2], $point->[3]);
	    my($nx, $ny) = ($x0+$vx, $y0+$vy);
	    if ($nx >= $w) {
		$nx = $w;
		$vx = -$vx;
	    } elsif ($nx <= 1) {
		$nx = 1;
		$vx = -$vx;
	    } elsif ($ny >= $h) {
		$ny = $h;
		$vy = -$vy;
	    } elsif ($ny <= 1) {
		$ny = 1;
		$vy = -$vy;
	    }
	    ($point->[0], $point->[1]) = ($nx, $ny);
	    ($point->[2], $point->[3]) = ($vx, $vy);
	}
	$tag = 'l' . $line_count++;
	$self->{line_count} = $line_count;
	my(@colors) = @{$self->{colors}};
	$canvas->createLine($points[0][0], $points[0][1],
			    $points[1][0], $points[1][1],
			    -tags => $tag, -fill => '#' . $colors[$line_count % scalar(@colors)]);
	$canvas->lower($tag);

    } elsif ($mez eq 'annoying_blink') {
	my $bg = $canvas->cget(-background);
	$canvas->configure(-background => $bg eq 'blue' ? 'green' : 'blue');
    } else {
	warn "Unrecognized mesmerize type '$mez', reverting to 'lines'.";
	$self->{Configure}{-mesmerize} = 'lines';
    } # end lines
    $canvas->idletasks;		# update() gives deep recursion!

} # end mesmerize

sub snooze {

    # Hide title and password entry by moving the items way off the canvas.

    my($self) = @_;

    my $canvas = $self->{canvas};
    $canvas->coords(1, -1000, -1000);
    $canvas->coords(2, -1000, -1000);

} # end snooze

sub unlock {$_[0]->{unlock}++}	# alert waitVariable() that we're done

1;
