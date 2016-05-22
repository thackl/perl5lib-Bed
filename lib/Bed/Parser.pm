package Bed::Parser;

use warnings;
use strict;

use Bed::Feature;

our $VERSION = '0.1.0';

=head1 NAME

Bed::Parser.pm

=head1 DESCRIPTION

Parser module for Bed format files.

=cut

=head1 SYNOPSIS

  use Bed::Parser;

  my $bp = Bed::Parser->new(file => ".bed");

  # ignore any features not on "chr1"
  $bp->add_condition(sub{ $_[0]->chrom eq 'chr1' })

  # header
  print $sp->header;

  # loop features
  while( my $feat = $gp->next_feature() ){
    print $feat->chromEnd;
  }

=cut

=head1 Constructor METHOD

=head2 new

Initialize a bed parser object. Takes parameters in key => value format.

  fh => \*STDIN,
  file => undef

  my $bp = Bed::Parser->new(file => ".bed"); # or
  my $bp = Bed::Parser->new(fh => \*BED);

=cut

my @ATTR_SCALAR = qw(header);

# init self
my %SELF;
@SELF{@ATTR_SCALAR} = (undef) x scalar @ATTR_SCALAR;

sub new{
	my $class = shift;

	my $self = {
            %SELF,              # defaults
            @_,                 # custom
            _buffer => [],      # protected
            _close_fh => undef,
	};

	bless $self, $class;

	# open file in read/write mode
        die "Either file or fh required\n" if ($self->file && $self->fh);
        $self->fh(\*STDIN) if (!$self->file && !$self->fh);
        $self->_file2fh if $self->file;

	return $self;
}

sub DESTROY{
    my $self = shift;
    # only close files opened with Parser
    close $self->fh if $self->{_close_fh};
}




############################################################################


=head1 Object METHODS

=head2 next_feature

Loop through bed file and return next 'Bed::Featuret' object (meeting previously
specified conditions).

=cut

sub next_feature{
    my ($self) = @_;
    # loop until condition is met
    while (defined (my $line = @{$self->{_buffer}} ? shift @{$self->{_buffer}} : readline($self->{fh}))){
        my $feat = Bed::Feature->new($line);
        $self->eval_feature($feat) || next;
        return $feat;
    }
    return; # eof
}

=head2 header

Get/set ...

=cut

sub _init_accessors{
    no strict 'refs';

    # generate simple accessors closure style
    foreach my $attr ( @ATTR_SCALAR ) {
        next if $_[0]->can($attr); # don't overwrite explicitly created subs
        *{__PACKAGE__ . "::$attr"} = sub {
            $_[0]->{$attr} = $_[1] if @_ == 2;
            return $_[0]->{$attr};
        }
    }
}

=head2 file

Get/set Bed file.

=cut

sub file{
    my ($self, $file) = @_;
    if (defined $file) {
        $self->{file} = $file;
        $self->_file2fh(); # update filehandle
    }
    return $self->{file};
}

=head2 fh

Get/set Bed fh. Update header cache.

=cut

sub fh{
    my ($self, $fh) = @_;
    if (defined $fh) {
        $self->{fh} = $fh;
        $self->_cache_header; # update header cache
    }
    return $self->{fh};
}

=head2 add_condition/reset_conditions

Only return features from parser satisfying custom condition using a predefined
function. The function is called with the feature object as first
parameter. Only features that evaluate to TRUE are returned by the parser.

  # customize parser to only return 'gene' features from '-' strand.
  $gp->add_condition(sub{
             my $feat = $_[0];
             return $feat->chromStart > 1000 && $feat->length > 1000;
         });


  # deactivate conditions
  $gp->reset_conditions();

=cut

sub add_condition{
    my ($self, $cond) = @_;

    if ($cond && ref($cond) eq 'CODE') {
        $self->{cond} ||= [];
        push @{$self->{cond}}, $cond;
    } else {
        die (((caller 0)[3])." requires condition as CODE reference!\n");
    }
    return $self->{cond};
}

sub reset_conditions{
    my ($self, $cond) = @_;
    $self->{cond} = [];
}

=head2 eval_feature

Returns TRUE if feature matches "conditions" set for parser.

  $gp->eval_feature($feat)

=cut

sub eval_feature{
    my ($self, $feat) = @_;
    if ($self->{cond}) {
        foreach ( @{$self->{cond}} ){ $_->($feat, $self) || return; }
    }
    return 1;
}

=head2 _file2fh

Open file handle.

=cut

sub _file2fh{
    my ($self) = @_;
    my $fh;
    open ($fh, $self->{file}) or die sprintf("%s: %s, %s",(caller 0)[3],$self->{file}, $!);
    $self->{_close_fh} = 1;
    $self->fh($fh);
}

=head2 _cache_header

Read and cache header from stream. Automatically done in ->new().

=cut

sub _cache_header{
    my ($self) = @_;
    my $fh = $self->fh;
    my $h = '';

    while (defined(my $l = <$fh>)) { # loop potential header lines
        unless ( $l =~ /^(track|browser)\s/ ){
            $self->{_buffer} = [$l]; # reset buffer
            last;
        }
        $h.= $l;
    }

    $self->{header} = $h;
}


# init closure accessors
__PACKAGE__->_init_accessors();

=head1 AUTHOR

Thomas Hackl S<thackl@lim4.de>

=cut



1;
