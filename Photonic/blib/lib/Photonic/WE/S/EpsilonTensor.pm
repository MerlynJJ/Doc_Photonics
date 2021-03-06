=head1 NAME

Photonic::WE::S::EpsilonTensor

=head1 VERSION

version 0.011

=head1 SYNOPSIS

   use Photonic::WE::S::EpsilonTensor;
   my $epsT=Photonic::WE::S::EpsilonTensor->new(metric=>$m, nh=>$nh);
   my $EpsTensor=$W->evaluate($epsB);

=head1 DESCRIPTION

Calculates the macroscopic dielectric tensor for a given fixed
Photonic::WE::S::Metric structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(metric=>$m, nh=>$nh, smallE=>$smallE, smallH=>$smallH,
keepStates=>$k)  

Initializes the structure.

$m Photonic::WE::S::Metric describing the structure and some parametres.

$nh is the maximum number of Haydock coefficients to use.

$smallH and $smallE are the criteria of convergence (default 1e-7) for
Haydock coefficients and for the continued fraction. From
Photonic::Roles::EpsParams.  

$k is a flag to keep states in Haydock calculations (default 0)

=item * evaluate($epsB)

Returns the macroscopic dielectric tensor for a given value of the
dielectric function of the particle $epsB. The host's
response $epsA is taken from the metric.  

=back

=head1 ACCESORS (read only)

=over 4

=item * epsilonTensor

The macroscopic dielectric tensor of the last operation

=item * All accesors of Photonic::WE::S::Wave


=back

=cut

package Photonic::WE::S::EpsilonTensor;
$Photonic::WE::S::EpsilonTensor::VERSION = '0.011';
use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::MatrixOps;
use Storable qw(dclone);
use PDL::IO::Storable;
use Photonic::Types;
use Moose;
use MooseX::StrictConstructor;

extends 'Photonic::WE::S::Wave'; 

has 'epsilonTensor' =>  (is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
			 lazy=>1, builder=>'_build_epsilonTensor',   
			 documentation=>'macroscopit response');


sub _build_epsilonTensor {
    my $self=shift;
    my $wave=$self->waveOperator;
    my $q=$self->metric->wavenumber;
    my $q2=$q*$q;
    my $k=$self->metric->wavevector;
    if($q->isa('PDL::Complex') || $k->isa('PDL::Complex')){
	#Make both complex
	map {$_=r2C($_) unless $_->isa('PDL::Complex')} $q, $k;
	my $k2=($k*$k)->sumover; #inner
	my $kk=$k->(:,:,*1)*$k->(:,*1,:); #outer
	my $id=identity($k);
	my $eps=$wave+$k2/$q2*$id - $kk/$q2;
	return $eps;
    }
    my $k2=$k->inner($k);
    my $kk=$k->outer($k);
    my $id=identity($k);
    my $eps=$wave+$k2/$q2*$id - $kk/$q2;
    return $eps;
};

__PACKAGE__->meta->make_immutable;
    
1;

__END__
