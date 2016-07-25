#!perl

use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::Mock::Simple;
use Test::More tests => 15;

use Devgru::Monitor;

use_ok( 'Devgru::Monitor::TSCMS' ) || print "Bail out!\n";

my $resp_mock = Test::Mock::Simple->new(module => 'HTTP::Response');
my $response_obj = HTTP::Response->new();
my $lwp_mock  = Test::Mock::Simple->new(module => 'LWP::UserAgent');
$lwp_mock->add(request => sub { return $response_obj; });

my %args = (
    node_data => {
        'arg1.arg2' => {
            template_vars => [qw(arg1 arg2)],
        },
        'arg3.arg4' => {
            template_vars => [qw(arg3 arg4)],
        },
    },
    type => 'TSCMS',
    up_frequency => 300,
    down_frequency => 60,
    down_confirm_count => 2,
    version_frequency => 86400,
    severity_thresholds => [ 25 ],
    check_timeout => 5,
    end_point_template => 'http://%s.%s.com/end_point',
);
my $monitor = Devgru::Monitor->new(%args);
my $node = $monitor->get_node('arg1.arg2');

$resp_mock->add(is_success => sub { return 1; });
$resp_mock->add(content    => sub { return q+{"overallStatus":"Success","applicationVersion":"1.0.33","hostnameInfo":{"hostname":"cfgsvc3.shared.jphx1.syseng.tmcs","hostClass":"cfgsvc","instanceNumber":3,"product":"shared","cluster":"jphx1","group":"syseng","isVip":false},"results":[{"statusResponse":{"status":"Success","statusDescription":"OK"},"dependency":{"name":"B2B Identity","uri":"http://igs.id.jetson1.coresys.tmcs:8080/identity-service/health/healthcheck","methodology":"Http 'GET' to 'http://igs.id.jetson1.coresys.tmcs:8080/identity-service/health/healthcheck'","isCritical":true}},{"statusResponse":{"status":"Success","statusDescription":{"database":"MySQL","hello":1}},"dependency":{"name":"MySQL Database","uri":"jdbc:mysql://db1.tscms.jphx1.syseng.tmcs:3306/tscms","methodology":"database_query","isCritical":true}}]}+; });
is($monitor->_check_node('arg1.arg2'), Devgru::Monitor->SERVER_UP, 'Node is up');
is($node->status, Devgru::Monitor->SERVER_UP, 'Node has correct status');
is($node->fail_reason, '', 'Fail reason is blank');
is($node->down_count, 0, 'Down Count is 0');

$resp_mock->add(content    => sub { return q+{"overallStatus":"Success","applicationVersion":"1.0.32","hostnameInfo":{"hostname":"cfgsvc3.shared.jphx1.syseng.tmcs","hostClass":"cfgsvc","instanceNumber":3,"product":"shared","cluster":"jphx1","group":"syseng","isVip":false},"results":[{"statusResponse":{"status":"Success","statusDescription":"OK"},"dependency":{"name":"B2B Identity","uri":"http://igs.id.jetson1.coresys.tmcs:8080/identity-service/health/healthcheck","methodology":"Http 'GET' to 'http://igs.id.jetson1.coresys.tmcs:8080/identity-service/health/healthcheck'","isCritical":true}},{"statusResponse":{"status":"Success","statusDescription":{"database":"MySQL","hello":1}},"dependency":{"name":"MySQL Database","uri":"jdbc:mysql://db1.tscms.jphx1.syseng.tmcs:3306/tscms","methodology":"database_query","isCritical":true}}]}+; });
is($monitor->_check_node('arg3.arg4'), Devgru::Monitor->SERVER_UP, 'Node is up with a different version');

$resp_mock->add(content    => sub { return q+{"overallStatus":"Unstable","applicationVersion":"1.0.33","hostnameInfo":{"hostname":"cfgsvc3.shared.jphx1.syseng.tmcs","hostClass":"cfgsvc","instanceNumber":3,"product":"shared","cluster":"jphx1","group":"syseng","isVip":false},"results":[{"statusResponse":{"status":"Success","statusDescription":"OK"},"dependency":{"name":"B2B Identity","uri":"http://igs.id.jetson1.coresys.tmcs:8080/identity-service/health/healthcheck","methodology":"Http 'GET' to 'http://igs.id.jetson1.coresys.tmcs:8080/identity-service/health/healthcheck'","isCritical":true}},{"statusResponse":{"status":"Success","statusDescription":{"database":"MySQL","hello":1}},"dependency":{"name":"MySQL Database","uri":"jdbc:mysql://db1.tscms.jphx1.syseng.tmcs:3306/tscms","methodology":"database_query","isCritical":true}}]}+; });
is($monitor->_check_node('arg1.arg2'), Devgru::Monitor->SERVER_UNSTABLE, 'Node is unstable');
is($node->status, Devgru::Monitor->SERVER_UNSTABLE, 'Node has correct status');
is($node->fail_reason, q+overallStatus was 'Unstable' instead of 'Success'+, 'Fail reason is correct');
is($node->down_count, 1, 'Down Count is 1');

$resp_mock->add(is_success => sub { return 0;  });
$resp_mock->add(content    => sub { return ''; });
is($monitor->_check_node('arg1.arg2'), Devgru::Monitor->SERVER_DOWN, 'Node is Down');
is($node->status, Devgru::Monitor->SERVER_DOWN, 'Node has correct status');
is($node->fail_reason, '', 'Fail reason is blank');
is($node->down_count, 2, 'Down Count is 2');

throws_ok { $monitor->_check_node() } qr/^No node name provided to _check_node/, 'No node name provided';
