
#
# GENERATED WITH PDL::PP! Don't modify!
#
package Photonic::ExtraUtils;

@EXPORT_OK  = qw( PDL::PP dgtsl PDL::PP cgtsl );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $Photonic::ExtraUtils::VERSION = 0.011;
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap Photonic::ExtraUtils $VERSION;





=head1 NAME

Photonic::ExtraUtils - Glue for utility Fortran routines

=head1 SYNOPSIS

       use Photonic::ExtraUtils;

       dgtsl($c, $d, $e, $b, $info=PDL->null);
       cgtsl($c, $d, $e, $b, $info=PDL->null);
      

=head1 DESCRIPTION

Call some fortran routines from perl code.       

=cut







=head1 FUNCTIONS



=cut





=head2 dgtsl

=for ref

Runs the LINPACK fortran routine DGTSL to solve a general tridiagonal
system of equations in double precission.

=for usage

       dgtsl($c, $d, $e, $b, $info=PDL->null);

where $c(1..$n-1) is the subdiagonal, $d(0..$n-1) the diagonal and
$e(0..$n-2) the supradiagonal of an $nX$n tridiagonal double precission
matrix. $b(0..$n-1) is the right hand side vector. $b is replaced by
the solution. $info returns 0 for success or k if the k-1-th element
of the diagonal became zero.


=head2 cgtsl

=for ref

Runs the LINPACK fortran routine CGTSL to solve a general complex tridiagonal
system of equations.

=for usage

       cgtsl($c, $d, $e, $b, $info=PDL->null);

where $c(2,1..$n-1) is the subdiagonal, $d(2,0..$n-1) the diagonal and
$e(2,0..$n-2) the supradiagonal of an $nX$n tridiagonal complex double precission
matrix. $b(2,0..$n-1) is the right hand side vector. $b is replaced by
the solution. $info returns 0 for success or k if the k-1-th element
of the diagonal became zero. Either 2Xn pdl's are used to represent
complex numbers, as in PDL::Complex.

=head2  set_boundscheck
=head2  set_debugging

=cut





=head2 dgtsl

=for sig

  Signature: ([phys] c(n); [phys] d(n); [phys] e(n); [phys] y(n); [o] b(n); int [o] info())


=for ref

info not available


=for bad

dgtsl does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





          sub PDL::dgtsl {
	      use Carp;
	      confess "Wrong number of arguments"
	       	      unless scalar(@_)==6 or scalar(@_)==4;
	      my ($c, $d, $e, $y, $b, $i)=@_;
	      $i=PDL->null unless defined $i;
	      map {
		  $_=$_->copy unless $_->is_inplace;
	          $_->set_inplace(0); 
              }  ($c, $d, $e);  
	      if($y->is_inplace){$b=$y}
	      elsif(not defined $b and not $y->is_inplace){
		  $b=$y->copy;
	      }elsif(defined $b and not $y->is_inplace){$b.=$y}
	      else {die "Weird";}
	      $y->set_inplace(0);
	      PDL::_dgtsl_int($c, $d, $e, $b, $b, $i);
	      return ($b, $i);
	      }
        

*dgtsl = \&PDL::dgtsl;





=head2 cgtsl

=for sig

  Signature: ([phys]c(2,n); [phys]d(2,n); [phys]e(2,n); [phys]y(2,n); [o] b(2,n); int [o] info())


=for ref

info not available


=for bad

cgtsl does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





          sub PDL::cgtsl {
	      use Carp;
	      use PDL::Complex;
	      confess "Wrong number of arguments"
	       	      unless scalar(@_)==6 or scalar(@_)==4;
	      my ($c, $d, $e, $y, $b, $i)=@_;
	      my $complex=$y->isa("PDL::Complex");
	      $i=PDL->null unless defined $i;
	      map {
		  $_=$_->copy unless $_->is_inplace;
	          $_->set_inplace(0); 
              }  ($c, $d, $e);  
	      if($y->is_inplace){$b=$y}
	      elsif(not defined $b and not $y->is_inplace){
		  $b=$y->copy;
	      }elsif(defined $b and not $y->is_inplace){$b.=$y}
	      else {die "Weird";}
	      PDL::_cgtsl_int($c, $d, $e, undef, $b, $i);
	      $y->is_inplace(0);
      	      return ($b->complex, $i) if $complex;
	      return ($b, $i) unless $complex;
	      }
        

*cgtsl = \&PDL::cgtsl;



;



# Exit with OK status

1;

		   