#!/usr/bin/env perl
use strict;
use warnings;

use Metabase::Client;
use Metabase::User::Profile;
use CPAN::Testers::Report;
use CPAN::Testers::ParseReport;
use Path::Class;

#--------------------------------------------------------------------------#
# process command line
#--------------------------------------------------------------------------#

my @files = @ARGV;
for my $f in ( @files ) {
  die "'$f' is not a readable file. Aborting.\n" unless -f $f;
}

#--------------------------------------------------------------------------#
# create a user for submissions
#--------------------------------------------------------------------------#

my $profile = Metabase::User::Profile->open(
  {
    resource => 'metabase:user:74B9A2EA-1D1A-11DE-BE21-DD62421C7A0A',
    guid     => '74B9A2EA-1D1A-11DE-BE21-DD62421C7A0A',
  }
);

$profile->add('Metabase::User::EmailAddress' => 'jdoe@example.com');
$profile->add('Metabase::User::FullName'     => 'John Doe');
$profile->add('Metabase::User::Secret'       => 'aixuZuo8');

$profile->close;

#--------------------------------------------------------------------------#
# create a client for submissions
#--------------------------------------------------------------------------#

die "not done writing this yet!";

