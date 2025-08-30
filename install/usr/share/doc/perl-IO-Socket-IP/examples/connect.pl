#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Poll;
use IO::Socket::IP;
use Socket qw( SOCK_STREAM );
use Getopt::Long;

GetOptions(
   'timeout=f' => \my $TIMEOUT,
) or exit 1;

my $host    = shift @ARGV or die "Need HOST\n";
my $service = shift @ARGV or die "Need SERVICE\n";

my $socket = IO::Socket::IP->new(
   PeerHost    => $host,
   PeerService => $service,
   Type        => SOCK_STREAM,
   Timeout     => $TIMEOUT,
) or die "Cannot connect to $host:$service - $IO::Socket::errstr";

printf STDERR "Connected to %s:%s\n", $socket->peerhost_service;

my $poll = IO::Poll->new;

$poll->mask( \*STDIN => POLLIN );
$poll->mask( $socket => POLLIN );

while(1) {
   $poll->poll( undef );

   if( $poll->events( \*STDIN ) ) {
      my $ret = STDIN->sysread( my $buffer, 8192 );
      defined $ret or die "Cannot read STDIN - $!\n";
      $ret or last;
      $socket->syswrite( $buffer );
   }
   if( $poll->events( $socket ) ) {
      my $ret = $socket->sysread( my $buffer, 8192 );
      defined $ret or die "Cannot read socket - $!\n";
      $ret or last;
      STDOUT->syswrite( $buffer );
   }
}
