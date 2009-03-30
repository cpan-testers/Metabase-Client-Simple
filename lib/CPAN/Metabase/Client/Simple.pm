use 5.006;
use strict;
use warnings;

package CPAN::Metabase::Client::Simple;

=head1 NAME

CPAN::Metabase::Client::Simple - a client that submits to CPAN Metabase servers

=cut

our $VERSION = '0.001';

use HTTP::Request::Common ();
use JSON;
use LWP::UserAgent;
use URI;

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

sub http_request {
  my ($self, $request) = @_;
  # Blah blah blah, it would be nice to cache this and maybe do some of that
  # keepalive stuff that the cool kids are all talking about.
  # -- rjbs, 2009-03-30
  LWP::UserAgent->new->request($request);
}

sub submit_fact {
  my ($self, $fact) = @_;

  my $path = sprintf 'submit/%s', $fact->type;

  # XXX: should be $self->profile->guid
  $fact->set_creator_id($self->profile->{metadata}{core}{guid}[1]);

  my $req_url = $self->abs_url($path);

  my $req = HTTP::Request::Common::POST(
    $req_url,
    Content_Type => 'application/json',
    Accept       => 'application/json',
    Content      => JSON->new->encode({
      fact      => $fact->as_struct,
      submitter => $self->profile, # XXX: should be ->as_struct
    }),
  );

  my $res = $self->http_request($req);
  Carp::confess("fact submission failed: " . $res->message)
    unless $res->is_success;

  # This wil be something more informational later, like "accepted" or
  # "queued," maybe. -- rjbs, 2009-03-30
  return 1;
}

sub retrieve_fact_raw {
  my ($self, $guid) = @_;

  # What do we want to do when you're asking for a fact /with your
  # credentials/?  Let's say, for now, that you never do this...
  # -- rjbs, 2009-03-30
  my $req_url = $self->abs_url("guid/$guid");

  my $req = HTTP::Request::Common::GET(
    $req_url,
    'Accept' => 'application/json',
  );

  my $res = $self->http_request($req);

  Carp::confess("fact retrieval failed: " . $res->message)
    unless $res->is_success;

  my $json = $res->content;

  JSON->new->decode($json);
}

sub abs_url {
  my ($self, $str) = @_;
  my $req_url = URI->new($str)->abs($self->url);
}

=head1 LICENSE

Copyright (C) 2008, Ricardo SIGNES.

This is free software, available under the same terms as perl itself.

=cut

1;
