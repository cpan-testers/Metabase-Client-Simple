use 5.006;
use strict;
use warnings;

package Metabase::Client::Simple;

our $VERSION = '0.001';

use HTTP::Request::Common ();
use JSON;
use LWP::UserAgent;
use URI;

=head1 NAME

Metabase::Client::Simple - a client that submits to Metabase servers

=head1 SYNOPSIS

  use Metabase::Client::Simple;
  use Metabase::User::Profile;

  my $profile = Metabase::User::Profile->load('user-profile-file');

  my $client = Metabase::Client::Simple->new({
    profile => $profile,
    url     => 'http://metabase.example.com/',
  });

  my $fact = generate_metabase_fact;

  $client->submit_fact($fact);

=head1 DESCRIPTION

Metabase::Client::Simple provides is extremely simple, lightweight library for
submitting facts to a L<Metabase|Metabase> web server.

=head1 METHODS

=cut

# Stolen from ::Fact.
# XXX: Should refactor this into something in Fact, which we can then rely on.
# -- rjbs, 2009-03-30
sub __validate_args {
  my ($self, $args, $spec) = @_;
  my $hash = (@$args == 1 and ref $args->[0]) ? { %{ $args->[0]  } }
           : (@$args == 0)                    ? { }
           :                                    { @$args };

  my @errors;

  for my $key (keys %$hash) {
    push @errors, qq{unknown argument "$key" when constructing $self}
      unless exists $spec->{ $key };
  }

  for my $key (grep { $spec->{ $_ } } keys %$spec) {
    push @errors, qq{missing required argument "$key" when constructing $self}
      unless defined $hash->{ $key };
  }

  Carp::confess(join qq{\n}, @errors) if @errors;

  return $hash;
}

=head2 new

  my $client = Metabase::Client::Simple->new(\%arg)

This is the object constructor.

Valid arguments are:

  profile - a Metabase::User::Profile object
  url     - the root URL for the metabase server

=cut

my @valid_args;
BEGIN {
  @valid_args = qw(profile url);

  for my $arg (@valid_args) {
    no strict 'refs';
    *$arg = sub { $_[0]->{$arg}; }
  }
}

sub new {
  my ($class, @args) = @_;

  my $args = $class->__validate_args(
    \@args,
    { map { $_ => 1 } @valid_args }
  );

  my $self = bless $args => $class;

  return $self;
}

sub _http_request {
  my ($self, $request) = @_;

  # Blah blah blah, it would be nice to cache this and maybe do some of that
  # keepalive stuff that the cool kids are all talking about.
  # -- rjbs, 2009-03-30
  LWP::UserAgent->new->request($request);
}

=head2 submit_fact

  $client->submit_fact($fact);

This method will submit a L<Metabase::Fact|Metabase::Fact> object to the
client's server.  On success, it will return a true value.  On failure, it will
raise an exception.

=cut

sub submit_fact {
  my ($self, $fact) = @_;

  my $path = sprintf 'submit/%s', $fact->type;

  # XXX: should be $self->profile->guid
  # XXX: or $self->profile->resource? -- dagolden, 2009-03-31
  $fact->set_creator_id($self->profile->guid)
    unless $fact->creator_id;

  my $req_url = $self->_abs_url($path);

  my $req = HTTP::Request::Common::POST(
    $req_url,
    Content_Type => 'application/json',
    Accept       => 'application/json',
    Content      => JSON->new->encode({
      fact      => $fact->as_struct,
      submitter => $self->profile->as_struct,
    }),
  );

  my $res = $self->_http_request($req);

  unless ($res->is_success) {
    if ($res->content_type eq 'application/json') {
      my $entity = JSON->new->decode($res->content);
      Carp::confess("fact submission failed: $entity->{error}");
    } else {
      Carp::confess("fact submission failed: " . $res->message)
    }
  }

  # This wil be something more informational later, like "accepted" or
  # "queued," maybe. -- rjbs, 2009-03-30
  return 1;
}

sub _abs_url {
  my ($self, $str) = @_;
  my $req_url = URI->new($str)->abs($self->url);
}

=head1 LICENSE

Copyright (C) 2008, Ricardo SIGNES.

This is free software, available under the same terms as perl itself.

=cut

1;
