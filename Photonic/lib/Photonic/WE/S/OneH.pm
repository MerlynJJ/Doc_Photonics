=head1 NAME

Photonic::OneH::R2

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use Photonic::OneH::R2;
    my $nr=Photonic::OneH::R2->new(metric=>$g, polarization=>$p);
    $nr->iterate;
    say $nr->iteration;
    say $nr->current_a;
    say $nr->next_b2;
    my $state=$nr->nextState;

=head1 DESCRIPTION

Implements calculation of Haydock coefficients and Haydock states for
the calculation of the retarded dielectric function of arbitrary
periodic two component systems in arbitrary number of dimentions. One
Haydock coefficient at a time.

=head1 METHODS

=over 4

=item * new(metric=>$m, polarization=>$e, [, smallH=>$s])

Create a new Ph::OneH::R2 object with PDL::Metric::R2 $m, with a
field along the complex direction $e and with smallness parameter  $s.

=back

=head1 ACCESORS (read only)

=over 4

=item * metric Photonic::Metric::R2 

A Photonic::Metric::R2 object defining the geometry of the
system, the charateristic function, the wavenumber, wavevector and
host dielectric function. Required in the initializer.

=item * polarization PDL::Complex

A non null vector defining the complex direction of the macroscopic
field. 

=item * smallH 

A small number used as tolerance to end the iteration. Small negative
b^2 coefficients are taken to be zero. From Photonic::Roles::EpsParams.

=item * B ndims dims epsilon

Accesors handled by metric (see Photonic::Metric::R2)

=item * previousState currentState nextState 

The n-1-th, n-th and n+1-th Haydock states; a complex vector for each
reciprocal wavevector

=item * current_a

The n-th Haydock coefficient a

=item * current_b2 next_b2 current_b next_b

The n-th and n+1-th b^2 and b Haydock coefficients

=item * next_c

The n+1-th c Haydock coefficient

=item * previous_g current_g next_g 

The n-1-th n-th and n+1-th g Haydock coefficients

=item * iteration

Number of completed iterations

=back

=head1 METHODS

=over 4

=item * iterate

Performs a single Haydock iteration and updates current_a, next_b,
next_b2, next_c, next_g, next_state, shifting the current values where
necessary. Returns 0 when unable to continue iterating. 

=item * $s=applymetric($g, $psi)

Returns the matrix of applying a  metric to the state; $g*psi.

=item * $s= _firstState($self)

Returns the fisrt state $v.

=item * $s=applyOperator($self, $psi_G)

Apply the Hamiltonian operator to state. State is ri:nx:ny... gnorm=i:nx:ny...

=item * $s=innerProduct($self, $left, $right)

Returns the inner product (Hamiltonian product) between states.

=item * $s=magnitude($self, $psi)

Returns the magnitude of a state gotten by taking the square root of the inner product of the state with itself, $self->innerProduct($psi, $psi)->abs->sqrt;.

=item * $c=changesign

Change sign to

=back

=cut



package Photonic::WE::S::OneH;
$Photonic::WE::S::OneH::VERSION = '0.011';

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 1916 by W. Luis Mochán

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA

    mochan@fis.unam.mx

    Instituto de Ciencias Físicas, UNAM
    Apartado Postal 48-3
    62251 Cuernavaca, Morelos
    México

=cut


use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::FFTW3;
use PDL::Complex;
use List::Util;
use Carp;
use Photonic::Types;
use Photonic::Utils qw(VSProd);
use Moose;
use MooseX::StrictConstructor;

has 'epsilon'=>(is=>'ro', isa=>'PDL::Complex', required=>1, lazy=>1,
		builder=>'_epsilon');
has 'metric'=>(is=>'ro', isa => 'Photonic::WE::S::Metric',
	       handles=>{B=>'B', ndims=>'ndims', dims=>'dims',
			 geometry=>'geometry', epsilonR=>'epsilon'},
	       required=>1);
has 'polarization' =>(is=>'ro', required=>1, isa=>'PDL::Complex');
has 'normalizedPolarization' =>(is=>'ro', isa=>'PDL::Complex',
     init_arg=>undef, writer=>'_normalizedPolarization');
has 'complexCoeffs'=>(is=>'ro', init_arg=>undef, default=>1,
		      documentation=>'Haydock coefficients are complex');
with 'Photonic::Roles::OneH',  'Photonic::Roles::UseMask';

sub _epsilon {
    my $self=shift;
    die "Coudln't obtain dielectric function from geometry" unless
	$self->geometry->can('epsilon');
    return $self->geometry->epsilon;
}

#Required by Photonic::Roles::OneH

sub applyOperator {
    my $self=shift;
    my $psi=shift; #psi is ri:xy:pm:nx:ny
    my $mask=undef;
    $mask=$self->mask if $self->use_mask;
    my $gpsi=$self->applyMetric($psi);
    # gpsi is ri:xy:pm:nx:ny. Get cartesian and pm out of the way and
    # transform to real space. Note FFFTW3 wants real PDL's[2,...]
    my $gpsi_r=ifftn($gpsi->real->mv(1,-1)->mv(1,-1), $self->ndims)->complex;
    #ri:nx:ny:xy:pm
    my $H=($self->epsilonR-$self->epsilon)/$self->epsilonR;
    my $Hgpsi_r=$H*$gpsi_r; #ri:nx:ny:xy:pm
    #Transform to reciprocal space, move xy and pm back and make complex,
    my $psi_G=fftn($Hgpsi_r->real, $self->ndims)->mv(-1,1)->mv(-1,1)->complex;
    #Apply mask
    #psi_G is ri:xy:pm:nx:ny mask is nx:ny
    $psi_G=$psi_G*$mask->(*1,*1) if defined $mask; #use dummies for xy:pm
    return $psi_G;

    return $psi_G;
}

sub applyMetric {
    my $self=shift;
    my $psi=shift;
    #psi is ri:xy:pm:nx:ny
    my $g=$self->metric->value;
    #$g is xy:xy:pm:nx:ny  or ri:xy:xy:pm:nx:ny
    #real or complex matrix times complex vector
    my $gpsi=($g*$psi(:,:,*1)) #ri:xy:xy:pm:nx:ny
	->sumover; #ri:xy:pm:nx:ny
    return $gpsi;
}

sub innerProduct {  #Return Hermitian product with metric
    my $self=shift;
    my $psi1=shift;
    my $psi2=shift;
    my $gpsi2=$self->applyMetric($psi2);
    return VSProd($psi1, $gpsi2);
}


sub magnitude {
    my $self=shift;
    my $psi=shift;
    return $self->innerProduct($psi, $psi)->abs->sqrt;
}
sub changesign { #don't change sign
    return 0;
}

sub _firstState { #\delta_{G0}
    my $self=shift;
    my $v=PDL->zeroes(2,2,@{$self->dims})->complex; #ri:pm:nx:ny...
    my $arg="(0),:" . ",(0)" x $self->ndims; #(0),(0),... ndims+1 times
    $v->slice($arg).=1/sqrt(2);
    my $e=$self->polarization; #ri:xy
    my $d=[$e->dims]->[1];
    croak "Polarization has wrong dimensions. " .
	  " Should be $d-dimensional complex vector."
	unless $e->isa('PDL::Complex') && $e->ndims==2 &&
	[$e->dims]->[0]==2 && [$e->dims]->[1]==$d;
    my $modulus2=$e->Cabs2->sumover;
    croak "Polarization should be non null" unless
	$modulus2 > 0;
    $e=$e/sqrt($modulus2);
    $self->_normalizedPolarization($e);
    #I'm using the same polarization for k and for -k. Could be
    #different (for chiral systems, for example
    my $phi=$e*$v(,*1); #initial state ordinarily normalized
                       # ri:xy:pm:nx:ny
    return $phi;
}


__PACKAGE__->meta->make_immutable;

1;
