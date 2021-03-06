=head1 NAME

Photonic::LE::NP::AllH

=head1 VERSION

version 0.011

=head1 SYNOPSIS

   use Photonic::LE::NP::AllH;
   my $iter=Photonic::LE::NP::AllH->new(
       epsilon=>$e, geometry=>$geometry,nh=>$Nh, keepStates=>$save); 
   $iter->run;
   my $haydock_as=$iter->as;
   my $haydock_bs=$iter->bs;
   my $haydock_b2s=$iter->b2s;
   my $haydock_states=$iter->states;

=head1 DESCRIPTION

Iterates the calculation of Haydock coefficients and states and saves
them for later retrieval. 

=head1 METHODS

=over 4

=item * new(epsilon=>$e, geometry=>$g, nh=>$nh, keepStates=>$k) 

Initializes an Ph::NR::NP::AllH object. $nh is the maximum number of desired
coefficients, $k is a flag, non zero to save the Haydock states. All
other arguments are as in Photonic::LE::NP::OneH.

=item * run

Runs the iteration to completion

=item * All the Photonic::LE::NP::OneH methods

=back

=head1 ACCESORS (read only)

=over 4

=item * nh

Maximum number of desired Haydock 'a' coefficients and states. The
number of b coefficients is one less.

=item * keepStates

Flag to keep (1) or discard (0) Haydock states

=item * states

Array of Haydock states

=item * as

Array of Haydock a coefficients

=item * bs

Array of Haydock b coefficients

=item * b2s

Array of Haydock b coefficients squared

=item * All the Photonic::LE::NP::OneH methods

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

package Photonic::LE::NP::AllH;
$Photonic::LE::NP::AllH::VERSION = '0.011';
use namespace::autoclean;
use Machine::Epsilon;
use PDL::Lite;
use PDL::NiceSlice;
use Photonic::Utils qw(EProd);
use Moose;
use MooseX::StrictConstructor;

extends 'Photonic::LE::NP::OneH';
with 'Photonic::Roles::AllH', 'Photonic::Roles::ReorthogonalizeC';

__PACKAGE__->meta->make_immutable;
    
1;
