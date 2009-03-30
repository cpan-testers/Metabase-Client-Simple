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
  @valid_args = qw(user key url);

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
  LWP::UserAgent->new->request($request);
}

sub submit_fact {
  my ($self, $fact) = @_;

  my $path = sprintf 'submit/%s', $fact->type;

  my $req_url = $self->abs_url($path);

  my $struct  = $fact->as_struct;

  my $req = HTTP::Request::Common::POST(
    $req_url,
    Content_Type => 'application/json',
    Accept       => 'application/json',
    Content      => JSON->new->encode($struct),
  );

  # Is it reasonable to return an HTTP::Response?  I don't know.  For now,
  # let's say yes.
  my $response = $self->http_request($req);
}

sub retrieve_fact {
  my ($self, $guid) = @_;

  my $req_url = $self->abs_url("guid/$guid");

  my $req
    = HTTP::Request::Common::GET($req_url, 'Accept' => 'application/json',);

  $self->http_request($req);
}

sub search {
  my ($self, $method, $args) = @_;

  my $req_url = $self->abs_url("search/" . join('/', $method, @$args));

  my $req
    = HTTP::Request::Common::GET($req_url, 'Accept' => 'application/json',);

  my $res = $self->http_request($req);

  die { response => $res } unless $res->is_success;

  my $results = JSON->new->allow_nonref(1)->decode($res->content);
  return ref $results ? @$results : ();
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
