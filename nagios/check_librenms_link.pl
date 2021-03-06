#!/usr/bin/perl
use strict;
use JSON;
use CGI qw/param/;
use LWP::UserAgent;

sub usage() {
    print "Usage: $0 token=022f592968d563b7881dd2445385daaf base=https://1.2.3.4:443 portid=1234 [warn=80] [critical=90]";
    exit 3;
}

my $token = param("token") or usage();
my $base = param("base") or usage();
my $portid = param("portid") or usage();
my $warn = param("warn") || "80";
my $crit = param("critical") || "90";

# Prepend https if protocol not shown
if ($base !~ /:/) { $base = "https://$base"; }
# Strip trailing / if provided
$base =~ s/\/$//;

my $ua = LWP::UserAgent->new(
timeout => 10,
ssl_opts => {
    verify_hostname => 0,
    SSL_verify_mode => 0,
},
);
$ua->default_header( 'X-Auth-Token' => $token );

my $resp = $ua->get("$base/api/v0/ports/$portid");
if ($resp->is_success == 0) {
    print "UNKNOWN: Can't poll LibreNMS: ".$resp->status_line."\n";
    exit 3;
}

my $json = $resp->decoded_content;

my $ref = decode_json $json;

my $ifName = $ref->{port}[0]->{ifName};
my $ifSpeed = $ref->{port}[0]->{ifSpeed};
my $inRate = $ref->{port}[0]->{ifInOctets_rate} * 8;
my $outRate = $ref->{port}[0]->{ifOutOctets_rate} * 8;

my $percentIn = "0";
my $percentOut = "0";
my $note = "";
if ($ifSpeed > 0) {
    $percentIn = sprintf("%.2f", 100 * ($inRate / $ifSpeed));
    $percentOut = sprintf("%.2f", 100 * ($outRate / $ifSpeed));
    if ($ifSpeed >= (1000 * 1000)) { $note = sprintf("%.1f", $ifSpeed/1000/1000)."Mbit"; }
    if ($ifSpeed >= (1000 * 1000 * 1000)) { $note = sprintf("%.1f", $ifSpeed/1000/1000/1000)."Gbit"; }
} else {
    $note = "$ifName IS SHUT";
}

my $state = "OK";
my $code = 0;
if ($percentIn > $warn || $percentOut > $warn) {
    $state = "WARNING";
    $code = 1;
}
if ($percentIn > $crit || $percentOut > $crit) {
    $state = "CRITICAL";
    $code = 2;
}

my $inMB = sprintf("%.2f", $inRate / 1000000);
my $outMB = sprintf("%.2f", $outRate / 1000000);
print "$state: $note. Avg_In= $inMB Mbps and Avg_Out= $outMB Mbps | inUsage=$percentIn%;$crit;$warn; outUsage=$percentOut%;$crit;$warn; inBandwidth=${inMB}MBs outBandwidth=${outMB}MBs";
exit $code;
