package Bed::Feature;

use warnings;
use strict;

use overload
    'bool' => sub{1},
    '""' => \&string;

our $VERSION = '0.1.0';

=head1 NAME

Bed::Feature

=head1 DESCRIPTION

Class for handling bed features.

=cut

=head1 SYNOPSIS

  use Bed::Feature;

  # usually get object from parser
  $bp = Bed::Parser->new(file => .bed);
  $feat = $bp->next_feature;

  # get values
  $feat->chrom
  $feat->chromStart
  $feat->chromEnd
  $feat->name # for bed or
  $feat->dataValue # for bedGraph
  ..

=head1 Constructor METHOD

=head2 new

Create a bed feature object. Takes either a gff line or a key => value
 representation of the gff fields.

=cut

my @ATTR_SCALAR = qw(chrom chromStart chromEnd name score strand thickStart thickEnd itemRgb blockCount blockSizes blockStarts);
my @ATTR_SCALAR_def = (undef) x @ATTR_SCALAR;

my %SELF;
@SELF{@ATTR_SCALAR} = @ATTR_SCALAR_def;

sub new{
	my $class = shift;
	my $self;

	if(@_ == 1){ # input is string to split
		my $bed = $_[0];
		chomp($bed);
		my %bed;
		@bed{@ATTR_SCALAR} = split(/[ \t]/,$bed, 12);
		$self = \%bed;
	}else{ # input is key -> hash structure
            $self = {
                %SELF,
                @_,
            };
	}

	return bless $self, $class;
}


=head1 Object METHODS

=head2 chrom chromStart chromEnd name score strand thickStart thickEnd itemRgb blockCount blockSizes blockStarts

Get/Set ...

  my $chr = $fear->chrom();
  $feat->name("some/thing");

=cut

# called at eof
sub _init_accessors{
    no strict 'refs';

    # generate accessors for cache affecting attributes
    foreach my $attr ( qw(pos cigar tlen seq) ) {
        next if $_[0]->can($attr); # don't overwrite explicitly created subs
        *{__PACKAGE__ . "::$attr"} = sub {
            if (@_ == 2){
                $_[0]->_reset_cached_values();
                $_[0]->{$attr} = $_[1];
            }
            return $_[0]->{$attr};
        }
    }

    # generate simple accessors closure style
    foreach my $attr ( @ATTR_SCALAR ) {
        next if $_[0]->can($attr); # don't overwrite explicitly created subs
        *{__PACKAGE__ . "::$attr"} = sub {
            $_[0]->{$attr} = $_[1] if @_ == 2;
            return $_[0]->{$attr};
        }
    }
}


=head2 string

Get stringified feature.

=cut

sub string{
    my ($self) = @_;
    my @s;
    foreach ( @ATTR_SCALAR ) { # get values up to first undef
        last if ! defined $self->{$_};
        push @s, $_;
    }
    return join("\t", @s),"\n";
}

=head2 length

=cut

sub length{
    my ($self) = @_;
    return $self->chromEnd - $self->chromStart;
}


# init auto-accessors at eof to prevent any overwrites
__PACKAGE__->_init_accessors();


=head1 AUTHOR

Thomas Hackl S<thackl@lim4.de>

=cut

1;
