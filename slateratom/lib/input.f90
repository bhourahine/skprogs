!> Module that reads input values from stdin.
module input

  use common_accuracy, only : dp
  use common_poisson, only : TBeckeGridParams

  use xcfunctionals, only : xcFunctional

  implicit none
  private

  public :: read_input_1, read_input_2, echo_input


contains

  !> Reads in all properties, except for occupation numbers.
  subroutine read_input_1(nuc, max_l, occ_shells, maxiter, scftol, poly_order, min_alpha,&
      & max_alpha, num_alpha, tAutoAlphas, alpha, conf_r0, conf_power, num_occ, num_power,&
      & num_alphas, xcnr, tPrintEigvecs, tZora, tBroyden, mixing_factor, xalpha_const, omega,&
      & camAlpha, camBeta, grid_params)

    !> nuclear charge, i.e. atomic number
    integer, intent(out) :: nuc

    !> maximum angular momentum
    integer, intent(out) :: max_l

    !> number of occupied shells
    integer, intent(out) :: occ_shells(0:4)

    !> maximum number of SCF calculations
    integer, intent(out) :: maxiter

    !> scf tolerance, i.e. convergence criteria
    real(dp), intent(out) :: scftol

    !> highest polynomial order + l in each shell
    integer, intent(out) :: poly_order(0:4)

    !> smallest exponent if automatically generate alphas, i.e. tAutoAlphas = .true.
    real(dp), intent(out) :: min_alpha

    !> largest exponent if automatically generate alphas, i.e. tAutoAlphas = .true.
    real(dp), intent(out) :: max_alpha

    !> number of exponents in each shell
    integer, intent(out) :: num_alpha(0:4)

    !> generate alphas automatically
    logical, intent(out) :: tAutoAlphas

    !> basis exponents
    real(dp), intent(out) :: alpha(0:4, 10)

    !> confinement radii
    real(dp), intent(out) :: conf_r0(0:4)

    !> power of confinement
    real(dp), intent(out) :: conf_power(0:4)

    !> maximal occupied shell
    integer, intent(out) :: num_occ

    !> maximum number of coefficients
    integer, intent(out) :: num_power

    !> maximum number of exponents
    integer, intent(out) :: num_alphas

    !> identifier of exchange-correlation type
    integer, intent(out) :: xcnr

    !> print eigenvectors to stdout
    logical, intent(out) :: tPrintEigvecs

    !> true, if zero-order regular approximation for relativistic effects is desired
    logical, intent(out) :: tZora

    !> true, if Broyden mixing is desired, otherwise simple mixing is applied
    logical, intent(out) :: tBroyden

    !> mixing factor
    real(dp), intent(out) :: mixing_factor

    !> exchange parameter for X-Alpha exchange
    real(dp), intent(out) :: xalpha_const

    !> range-separation parameter
    real(dp), intent(out) :: omega

    !> CAM alpha parameter
    real(dp), intent(out) :: camAlpha

    !> CAM beta parameter
    real(dp), intent(out) :: camBeta

    !> holds parameters, defining a Becke integration grid
    type(TBeckeGridParams), intent(out) :: grid_params

    !! auxiliary variables
    integer :: ii, jj

    omega = 0.0_dp
    camAlpha = 0.0_dp
    camBeta = 0.0_dp

    write(*, '(A)') 'Enter nuclear charge, maximal angular momentum (s=0), max. SCF, SCF tol., ZORA'
    read(*,*) nuc, max_l, maxiter, scftol, tZora

    write(*, '(A)') 'Enter XC functional:&
        & 0: HF, 1: X-Alpha, 2: LDA-PW91, 3: GGA-PBE96, 4: GGA-BLYP, 5: LCY-PBE96, 6: LCY-BNL,&
        & 7: PBE0, 8: B3LYP, 9: CAMY-B3LYP, 10: CAMY-PBEh'
    read(*,*) xcnr

    if (xcFunctional%isNotImplemented(xcnr)) then
      write(*, '(A,I2,A)') 'XCNR=', xcnr, ' not implemented!'
      stop
    end if

    if (xcFunctional%isLongRangeCorrected(xcnr)) then
      camBeta = 1.0_dp
      write(*, '(A)') 'Enter range-separation parameter:'
      read(*,*) omega
    elseif (xcnr == xcFunctional%HYB_PBE0) then
      ! currently only HYB-PBE0 does support arbitrary HFX portions (HYB-B3LYP does not)
      write(*, '(A)') 'Enter portion of HFX (CAM alpha):'
      read(*,*) camAlpha
    elseif (xcnr == xcFunctional%HYB_B3LYP) then
      camAlpha = 0.2_dp
    elseif (xcFunctional%isCAMY(xcnr)) then
      write(*, '(A)') 'Enter range-separation parameter, CAM alpha, CAM beta:'
      read(*,*) omega, camAlpha, camBeta
    end if

    if (xcFunctional%isLongRangeCorrected(xcnr) .or. xcFunctional%isCAMY(xcnr)&
        & .or. xcFunctional%isGlobalHybrid(xcnr)) then
      write(*, '(A)') 'NRadial NAngular ll_max rm'
      read(*,*) grid_params%nRadial, grid_params%nAngular, grid_params%ll_max, grid_params%rm
    end if

    if ((xcnr == xcFunctional%HF_Exchange) .and. tZora) then
      write(*, '(A)') 'ZORA only available for DFT!'
      stop
    end if
    if (xcnr == xcFunctional%X_Alpha) then
      write(*, '(A)') 'Enter empirical parameter for X-Alpha exchange.'
      read(*,*) xalpha_const
    end if

    if (max_l > 4) then
      write(*, '(A)') 'Sorry, l=', max_l, ' is a bit too large. No nuclear weapons allowed.'
      stop
    end if

    write(*, '(A)') 'Enter Confinement: r_0 and integer power, power=0.0 -> off'
    do ii = 0, max_l
      write(*, '(A,I3)') 'l=', ii
      read(*,*) conf_r0(ii), conf_power(ii)
    end do

    write(*, '(A)') 'Enter number of occupied shells for each angular momentum.'
    do ii = 0, max_l
      write(*, '(A,I3)') 'l=', ii
      read(*,*) occ_shells(ii)
    end do

    write(*, '(A)') 'Enter number of exponents and polynomial coefficients for each angular ' //&
        & 'momentum.'
    do ii = 0, max_l
      write(*, '(A,I3)') 'l=', ii
      read(*,*) num_alpha(ii), poly_order(ii)
      if (num_alpha(ii) > 10) then
        write(*, '(A)') ' Sorry, number of exponents in each shell must be smaller than 11.'
        stop
      end if
    end do

    write(*, '(A)') 'Do you want to automatically generate the exponents (.true./.false.)?'
    read(*,*) tAutoAlphas

    if (tAutoAlphas) then
      ! automatically generate alphas
      do ii = 0, max_l
        write(*, '(A)') 'Enter smallest exponent and largest exponent.'
        read(*,*) min_alpha, max_alpha
        call gen_alphas(min_alpha, max_alpha, num_alpha(ii), alpha(ii, :))
      end do
    else
      do ii = 0, max_l
        write(*, '(A,I3,A,I3,A)') 'Enter ', num_alpha(ii), 'exponents for l=', ii, ', one per line.'
        do jj = 1, num_alpha(ii)
          read(*,*) alpha(ii, jj)
        end do
      end do
    end if

    num_occ = 0
    do ii = 0, max_l
      num_occ = max(num_occ, occ_shells(ii))
    end do

    num_power = 0
    do ii = 0, max_l
      num_power = max(num_power, poly_order(ii))
    end do

    num_alphas = 0
    do ii = 0, max_l
      num_alphas = max(num_alphas, num_alpha(ii))
    end do

    write(*, '(A)') 'Print Eigenvectors ? .true./.false.'
    read(*,*) tPrintEigvecs

    write(*, '(A)') ' Use Broyden mixer (.true./.false.)? And mixing parameter <1'
    read(*,*) tBroyden, mixing_factor

  end subroutine read_input_1


  !> Reads in occupation numbers and quantum numbers of wavefunctions to write out.
  subroutine read_input_2(occ, max_l, occ_shells, qnvalorbs)

    !> occupation numbers
    real(dp), intent(out) :: occ(:,0:,:)

    !> maximum angular momentum
    integer, intent(in) :: max_l

    !> number of occupied shells
    integer, intent(in) :: occ_shells(0:)

    !> quantum numbers of wavefunctions to be written
    integer, intent(out) :: qnvalorbs(:,0:)

    !> auxiliary variables
    integer :: ii, jj

    occ(:,:,:) = 0.0_dp

    write(*, '(A)') 'Enter the occupation numbers for each angular momentum and shell, up and ' //&
        & 'down in one row.'

    write(*, '(A)') ' '
    write(*, '(A)') 'UP Electrons; DOWN Electrons'
    do ii = 0, max_l
      do jj = 1, occ_shells(ii)
        write(*, '(A,I3,A,I3)') 'l= ', ii, ' and shell ', jj
        read(*,*) occ(1, ii, jj), occ(2, ii, jj)
      end do
    end do

    write(*, '(A)') 'Quantum numbers of wavefunctions to be written:'
    do ii = 0, max_l
      write(*, '(A,I0,A)') 'l= ', ii, ': from to'
      read(*,*) qnvalorbs(:, ii)
      qnvalorbs(:, ii) = [minval(qnvalorbs(:, ii)), maxval(qnvalorbs(:, ii))]
      qnvalorbs(:, ii) = qnvalorbs(:, ii) - ii
    end do

  end subroutine read_input_2


  !> Echos gathered input to stdout.
  subroutine echo_input(nuc, max_l, occ_shells, maxiter, scftol, poly_order, num_alpha, alpha,&
      & conf_r0, conf_power, occ, num_occ, num_power, num_alphas, xcnr, tZora, num_mesh_points,&
      & xalpha_const)

    !> nuclear charge, i.e. atomic number
    integer, intent(in) :: nuc

    !> maximum angular momentum
    integer, intent(in) :: max_l

    !> number of occupied shells
    integer, intent(in) :: occ_shells(0:)

    !> maximum number of SCF calculations
    integer, intent(in) :: maxiter

    !> scf tolerance, i.e. convergence criteria
    real(dp), intent(in) :: scftol

    !> highest polynomial order + l in each shell
    integer, intent(in) :: poly_order(0:)

    !> number of exponents in each shell
    integer, intent(in) :: num_alpha(0:)

    !> basis exponents
    real(dp), intent(in) :: alpha(0:,:)

    !> confinement radii
    real(dp), intent(in) :: conf_r0(0:)

    !> power of confinement
    real(dp), intent(in) :: conf_power(0:)

    !> occupation numbers
    real(dp), intent(in) :: occ(:,0:,:)

    !> maximal occupied shell
    integer, intent(in) :: num_occ

    !> maximum number of coefficients
    integer, intent(in) :: num_power

    !> maximum number of exponents
    integer, intent(in) :: num_alphas

    !> identifier of exchange-correlation type
    integer, intent(in) :: xcnr

    !> true, if zero-order regular approximation for relativistic effects is desired
    logical, intent(in) :: tZora

    !> number of numerical integration points
    integer, intent(in) :: num_mesh_points

    !> exchange parameter for X-Alpha exchange
    real(dp), intent(in) :: xalpha_const

    !> auxiliary variables
    integer :: ii, jj

    write(*, '(A)') ' '
    write(*, '(A)') '--------------'
    write(*, '(A)') 'INPUT SUMMARY '
    write(*, '(A)') '--------------'

    if (tZora) write(*, '(A)') 'SCALAR RELATIVISTIC ZORA CALCULATION'
    if (.not. tZora) write(*, '(A)') 'NON-RELATIVISTIC CALCULATION'
    write(*, '(A)') ' '

    write(*, '(A,I3)') 'Nuclear Charge: ', nuc

    if (xcnr == xcFunctional%HF_Exchange) write(*, '(A)') 'Hartree-Fock exchange'
    if (xcnr == xcFunctional%X_Alpha) write(*, '(A,F12.8)') 'X-Alpha, alpha= ', xalpha_const
    if (xcnr == xcFunctional%LDA_PW91) write(*, '(A)') 'LDA, Perdew-Wang Parametrization'
    if (xcnr == xcFunctional%GGA_PBE96) write(*, '(A)') 'PBE96'
    if (xcnr == xcFunctional%GGA_BLYP) write(*, '(A)') 'BLYP'
    if (xcnr == xcFunctional%LCY_PBE96) write(*, '(A)') 'Range-separated: LCY-PBE96'
    if (xcnr == xcFunctional%LCY_BNL) write(*, '(A)') 'Range-separated: BNL,&
        & LCY-LDA for exchange + PBE correlation'
    if (xcnr == xcFunctional%HYB_PBE0) write(*, '(A)') 'Global hybrid: PBE0'
    if (xcnr == xcFunctional%HYB_B3LYP) write(*, '(A)') 'Global hybrid: B3LYP'
    if (xcnr == xcFunctional%CAMY_B3LYP) write(*, '(A)') 'CAM: CAMY-B3LYP'
    if (xcnr == xcFunctional%CAMY_PBEh) write(*, '(A)') 'CAM: CAMY-PBEh'

    write(*, '(A,I6)') 'Max. number of SCF iterations: ', maxiter
    write(*, '(A,ES9.2E2)') 'SCF tolerance [a.u.]: ', scftol

    write(*, '(A,I1)') 'Max. angular momentum: ', max_l
    write(*, '(A,I5)') 'Number of points for numerical radial integration: ', num_mesh_points

    write(*, '(A)') ' '
    do ii = 0, max_l
      write(*, '(A,I1,A,I2)') 'Occupied Shells for l=', ii, ': ', occ_shells(ii)
    end do

    write(*, '(A)') ' '
    do ii = 0, max_l
      write(*, '(A,I1,A,I2)') 'Number of Polynomial Coeff. for l=', ii, ': ', poly_order(ii)
    end do

    do ii = 1, max_l
      if ((poly_order(ii) /= poly_order(0)) .and. (xcFunctional%isLongRangeCorrected(xcnr))) then
        write(*,*) 'LC functionals: polynomial orders need to be same for all shells.'
        stop
      end if
    end do

    write(*, '(A)') ' '
    do ii = 0, max_l
      write(*, '(A,I1)') 'Exponents for l=', ii
      do jj = 1, num_alpha(ii)
        write(*, '(F12.8)') alpha(ii, jj)
      end do
    end do

    write(*, '(A)') ' '
    write(*, '(A)') 'Occupation Numbers UP/DWN'
    do ii = 0, max_l
      do jj = 1, occ_shells(ii)
        write(*, '(A,I1,A,I2,A,2F12.8)') 'Angular Momentum ', ii, ' Shell ', jj, ': ',&
            & occ(1, ii, jj), occ(2, ii, jj)
      end do
    end do

    write(*, '(A)') ' '
    do ii = 0, max_l
      if (conf_power(ii) > 1.0e-06_dp) then
        write(*, '(A,I3,A,E15.7,A,E15.7)') 'l= ', ii, ', r0= ', conf_r0(ii), ' power= ',&
            & conf_power(ii)
      else
        write(*, '(A,I3,A)') 'l= ', ii, ' no confinement '
      end if
    end do

    write(*, '(A)') ' '
    write(*, '(A,I2,A)') 'There are at maximum ', num_occ, ' occ. shells for one l'
    write(*, '(A,I2,A)') 'There are at maximum ', num_power, ' coefficients for one exponent'
    write(*, '(A,I2,A)') 'There are at maximum ', num_alphas, ' exponents'

    write(*, '(A)') ' '
    write(*, '(A)') '------------------'
    write(*, '(A)') 'END INPUT SUMMARY '
    write(*, '(A)') '------------------'
    write(*, '(A)') ' '

  end subroutine echo_input


  !> Generates alpha coefficients for Slater expansion.
  subroutine gen_alphas(min_alpha, max_alpha, num_alpha, alpha)

    !> smallest exponent if automatically generate alphas, i.e. tAutoAlphas = .true.
    real(dp), intent(in) :: min_alpha

    !> largest exponent if automatically generate alphas, i.e. tAutoAlphas = .true.
    real(dp), intent(in) :: max_alpha

    !> number of exponents in each shell
    integer, intent(in) :: num_alpha

    !> generated basis exponents
    real(dp), intent(out) :: alpha(10)

    !> auxiliary variables
    real(dp) :: beta(10), ff

    !> auxiliary variable
    integer :: ii

    alpha(:) = 0.0_dp
    alpha(1) = min_alpha

    if (num_alpha == 1) return

    ff = (max_alpha / alpha(1))**(1.0_dp / real(num_alpha - 1, dp))

    do ii = 1, num_alpha - 1
      alpha(1 + ii) = alpha(ii) * ff
    end do

    do ii = 1, num_alpha
      beta(num_alpha + 1 - ii) = alpha(ii)
    end do

    do ii = 1, num_alpha
      alpha(ii) = beta(ii)
    end do

  end subroutine gen_alphas

end module input
