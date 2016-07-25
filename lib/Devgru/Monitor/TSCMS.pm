package Devgru::Monitor::TSCMS;

use 5.006;
use strict;
use warnings;

use parent qw(Devgru::Monitor);

=head1 NAME

Devgru::Monitor::TSCMS - TSCMS monitor

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use constant SUCCESS_KEY     => 'overallStatus';
use constant SUCCESS_VALUE   => 'Success';
use constant VERSION_KEY     => 'applicationVersion';

=head1 SYNOPSIS

This should not be called directly.  This will be instantiated through the use
of Devgru::Monitor.

=head1 SUBROUTINES/METHODS

=head2 _check_node

Connect to the nodes endpoint (healthcheck) and record what was found.

=cut

sub _check_node {
    my $self = shift;
    my $node_name = shift || croak("No node name provided to _check_node");

    my $ua = LWP::UserAgent->new();
    $ua->timeout($self->check_timeout);
    $ua->agent(__PACKAGE__ . '/' . $VERSION);


    my $node = $self->get_node($node_name);

    my $req = HTTP::Request->new(GET => $node->end_point);
    my $res = $ua->request($req);

    my $status = $self->SERVER_DOWN; # server is down
    $node->fail_reason('');
    if ($res->is_success) {
        my $healthcheck = JSON::XS->new->utf8->decode($res->content);
        $node->current_version($healthcheck->{VERSION_KEY()});
        if ($healthcheck->{SUCCESS_KEY()} eq SUCCESS_VALUE()) {
            $status = $self->SERVER_UP;
            $node->down_count(0);
        }
        else {
            $status = $self->SERVER_UNSTABLE;
            $node->fail_reason(SUCCESS_KEY . " was '"
                . $healthcheck->{SUCCESS_KEY()} . "' instead of '"
                . SUCCESS_VALUE . "'");
            $node->inc_down_count;
        }
    }
    else {
        $status = $self->SERVER_DOWN;
        $node->inc_down_count;
    }

    $node->status($status);
    return $status;
}

sub version_report {
    my $self = shift;

    my $last_check = $self->last_version_check;
    my @report = ();
    if (!$last_check || (time - $last_check > $self->version_frequency)) {
        my %data = ();
        my $good_report = 1;
        foreach my $node ($self->get_node_names) {
            my $node = $self->get_node($node);
            if ($node->current_version) {
                push(@{$data{$node->current_version}}, $node);
            }
            else {
                $good_report = 0;
                last;
            }
        }

        if ($good_report) {
            foreach my $version (keys %data) {
                push(@report, [ $version, @{$data{$version}} ]);
            }
            $self->last_version_check(time);
        }
    }

    return @report;
}

=head1 AUTHOR

Erik Tank, C<< <tank at jundy.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devgru-monitor-tscms at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devgru-Monitor-TSCMS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devgru::Monitor::TSCMS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devgru-Monitor-TSCMS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devgru-Monitor-TSCMS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devgru-Monitor-TSCMS>

=item * Search CPAN

L<http://search.cpan.org/dist/Devgru-Monitor-TSCMS/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Erik Tank.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Devgru::Monitor::TSCMS
