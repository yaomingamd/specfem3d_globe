!=====================================================================
!
!          S p e c f e m 3 D  G l o b e  V e r s i o n  4 . 0
!          --------------------------------------------------
!
!          Main authors: Dimitri Komatitsch and Jeroen Tromp
!    Seismological Laboratory, California Institute of Technology, USA
!                    and University of Pau, France
! (c) California Institute of Technology and University of Pau, April 2007
!
!    A signed non-commercial agreement is required to use this program.
!   Please check http://www.gps.caltech.edu/research/jtromp for details.
!           Free for non-commercial academic research ONLY.
!      This program is distributed WITHOUT ANY WARRANTY whatsoever.
!      Do not redistribute this program without written permission.
!
!=====================================================================

! compute the approximate amount of static memory needed to run the solver

  subroutine memory_eval(ATTENUATION,ATTENUATION_3D,ANISOTROPIC_3D_MANTLE,&
                       TRANSVERSE_ISOTROPY,ANISOTROPIC_INNER_CORE,ROTATION,&
                       SIMULATION_TYPE,SAVE_FORWARD,MOVIE_VOLUME,&
                       ONE_CRUST,doubling_index,this_region_has_a_doubling,&
                       ner,NEX_PER_PROC_XI,NEX_PER_PROC_ETA,ratio_sampling_array,&
                       NSPEC,nglob,static_memory_size)

  implicit none

  include "constants.h"

! input
  logical, intent(in) :: TRANSVERSE_ISOTROPY,ANISOTROPIC_3D_MANTLE,ANISOTROPIC_INNER_CORE, &
             ROTATION,MOVIE_VOLUME,ATTENUATION_3D,ATTENUATION,SAVE_FORWARD,ONE_CRUST
  integer, dimension(MAX_NUM_REGIONS), intent(in) :: NSPEC, nglob
  integer, intent(in) :: SIMULATION_TYPE,NEX_PER_PROC_XI,NEX_PER_PROC_ETA
  integer, dimension(MAX_NUMBER_OF_MESH_LAYERS), intent(in) :: doubling_index
  logical, dimension(MAX_NUMBER_OF_MESH_LAYERS), intent(in) :: this_region_has_a_doubling
  integer, dimension(MAX_NUMBER_OF_MESH_LAYERS), intent(in) :: ner,ratio_sampling_array

! output
  double precision, intent(out) :: static_memory_size

! variables
  integer :: NSPEC_CRUST_MANTLE_ATTENUAT,NSPEC_INNER_CORE_ATTENUATION,NSPECMAX_ISO_MANTLE,&
             NSPECMAX_TISO_MANTLE,NSPECMAX_ANISO_MANTLE,NSPECMAX_ANISO_IC,NSPEC_OUTER_CORE_ROTATION,&
             ilayer,NUMBER_OF_MESH_LAYERS,ner_without_doubling,ispec_aniso

! generate the elements in all the regions of the mesh
  ispec_aniso = 0

  if (ONE_CRUST) then
    NUMBER_OF_MESH_LAYERS = MAX_NUMBER_OF_MESH_LAYERS - 1
  else
    NUMBER_OF_MESH_LAYERS = MAX_NUMBER_OF_MESH_LAYERS
  endif

! count anisotropic elements
  do ilayer = 1, NUMBER_OF_MESH_LAYERS
      if (doubling_index(ilayer) == IFLAG_220_80 .or. doubling_index(ilayer) == IFLAG_80_MOHO) then
          ner_without_doubling = ner(ilayer)
          if(this_region_has_a_doubling(ilayer)) then
              ner_without_doubling = ner_without_doubling - 2
              ispec_aniso = ispec_aniso + &
              (NSPEC_DOUBLING_SUPERBRICK*(NEX_PER_PROC_XI/ratio_sampling_array(ilayer)/2)* &
              (NEX_PER_PROC_ETA/ratio_sampling_array(ilayer)/2))
          endif
          ispec_aniso = ispec_aniso + &
          ((NEX_PER_PROC_XI/ratio_sampling_array(ilayer))*(NEX_PER_PROC_ETA/ratio_sampling_array(ilayer))*ner_without_doubling)
      endif
  enddo

  if(ATTENUATION) then
    NSPEC_CRUST_MANTLE_ATTENUAT = NSPEC(IREGION_CRUST_MANTLE)
    NSPEC_INNER_CORE_ATTENUATION = NSPEC(IREGION_INNER_CORE)
  else
    NSPEC_CRUST_MANTLE_ATTENUAT = 1
    NSPEC_INNER_CORE_ATTENUATION = 1
  endif
  if(ANISOTROPIC_3D_MANTLE) then
    NSPECMAX_ISO_MANTLE = 1
    NSPECMAX_TISO_MANTLE = 1
    NSPECMAX_ANISO_MANTLE = NSPEC(IREGION_CRUST_MANTLE)
  else
    NSPECMAX_ISO_MANTLE = NSPEC(IREGION_CRUST_MANTLE)
    if(TRANSVERSE_ISOTROPY) then
      NSPECMAX_TISO_MANTLE = ispec_aniso
    else
      NSPECMAX_TISO_MANTLE = 1
    endif
    NSPECMAX_ANISO_MANTLE = 1
  endif
  if(ANISOTROPIC_INNER_CORE) then
    NSPECMAX_ANISO_IC = NSPEC(IREGION_INNER_CORE)
  else
    NSPECMAX_ANISO_IC = 1
  endif
  if(ROTATION) then
    NSPEC_OUTER_CORE_ROTATION = NSPEC(IREGION_OUTER_CORE)
  else
    NSPEC_OUTER_CORE_ROTATION = 1
  endif

! add size of each set of static arrays

  static_memory_size = 0.d0

! R_memory_crust_mantle
  static_memory_size = static_memory_size + 5.d0*dble(N_SLS)*dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPEC_CRUST_MANTLE_ATTENUAT*dble(CUSTOM_REAL)

! R_memory_inner_core
  static_memory_size = static_memory_size + 5.d0*dble(N_SLS)*dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPEC_INNER_CORE_ATTENUATION*dble(CUSTOM_REAL)

!!!!!!!!!!!!! DK DK this should be allocated only if Stacey conditions are active
! rho_vp_crust_mantle,rho_vs_crust_mantle
  static_memory_size = static_memory_size + dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPEC(IREGION_CRUST_MANTLE)*2.d0*dble(CUSTOM_REAL)

! xix_crust_mantle,xiy_crust_mantle,xiz_crust_mantle
! etax_crust_mantle,etay_crust_mantle,etaz_crust_mantle,
! gammax_crust_mantle,gammay_crust_mantle,gammaz_crust_mantle,jacobian_crust_mantle
  static_memory_size = static_memory_size + dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPEC(IREGION_CRUST_MANTLE)*10.d0*dble(CUSTOM_REAL)

! ibool_crust_mantle
  static_memory_size = static_memory_size + dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPEC(IREGION_CRUST_MANTLE)*dble(SIZE_REAL)

!!!!!!!!!!!!! DK DK this should be allocated only if Stacey conditions are active
! vp_outer_core
  static_memory_size = static_memory_size + dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPEC(IREGION_OUTER_CORE)*dble(CUSTOM_REAL)

! xix_outer_core,xiy_outer_core,xiz_outer_core,
! etax_outer_core,etay_outer_core,etaz_outer_core,
! gammax_outer_core,gammay_outer_core,gammaz_outer_core,jacobian_outer_core
! rhostore_outer_core,kappavstore_outer_core
  static_memory_size = static_memory_size + dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPEC(IREGION_OUTER_CORE)*12.d0*dble(CUSTOM_REAL)

! ibool_outer_core
  static_memory_size = static_memory_size + dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPEC(IREGION_OUTER_CORE)*dble(SIZE_REAL)

! updated_dof_ocean_load, idoubling_crust_mantle
  static_memory_size = static_memory_size + nglob(IREGION_CRUST_MANTLE)*2.d0*dble(SIZE_REAL)

! xstore_crust_mantle,ystore_crust_mantle,zstore_crust_mantle,rmass_crust_mantle
  static_memory_size = static_memory_size + nglob(IREGION_CRUST_MANTLE)*4.d0*dble(CUSTOM_REAL)

!!!!!!!!!!!!! DK DK this should be allocated only if oceans are active
! rmass_ocean_load
  static_memory_size = static_memory_size + nglob(IREGION_CRUST_MANTLE)*dble(CUSTOM_REAL)

!!!!!!!!!!!!! DK DK what is this??? check!!! related to anisotropy
  static_memory_size = static_memory_size + dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPECMAX_ISO_MANTLE*3.d0*dble(CUSTOM_REAL)
  static_memory_size = static_memory_size + dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPECMAX_TISO_MANTLE*3.d0*dble(CUSTOM_REAL)
  static_memory_size = static_memory_size + dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPECMAX_ANISO_MANTLE*21.d0*dble(CUSTOM_REAL)

! displ_crust_mantle,veloc_crust_mantle,accel_crust_mantle
  static_memory_size = static_memory_size + dble(NDIM)*nglob(IREGION_CRUST_MANTLE)*3.d0*dble(CUSTOM_REAL)

! xstore_outer_core, ystore_outer_core, zstore_outer_core, rmass_outer_core, displ_outer_core, veloc_outer_core, accel_outer_core
  static_memory_size = static_memory_size + nglob(IREGION_OUTER_CORE)*7.d0*dble(CUSTOM_REAL)

! ibool_inner_core
  static_memory_size = static_memory_size + dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPEC(IREGION_INNER_CORE)*dble(SIZE_REAL)

! xix_inner_core,xiy_inner_core,xiz_inner_core,
! etax_inner_core,etay_inner_core,etaz_inner_core,
! gammax_inner_core,gammay_inner_core,gammaz_inner_core,jacobian_inner_core,
! rhostore_inner_core, kappavstore_inner_core,muvstore_inner_core
  static_memory_size = static_memory_size + dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPEC(IREGION_INNER_CORE)*13.d0*dble(CUSTOM_REAL)

! xstore_inner_core,ystore_inner_core,zstore_inner_core,rmass_inner_core
  static_memory_size = static_memory_size + nglob(IREGION_INNER_CORE)*4.d0*dble(CUSTOM_REAL)

! c11store_inner_core,c33store_inner_core,c12store_inner_core,c13store_inner_core,c44store_inner_core
  static_memory_size = static_memory_size + dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPECMAX_ANISO_IC*5.d0*dble(CUSTOM_REAL)

! displ_inner_core,veloc_inner_core,accel_inner_core
  static_memory_size = static_memory_size + dble(NDIM)*nglob(IREGION_INNER_CORE)*3.d0*dble(CUSTOM_REAL)

! A_array_rotation,B_array_rotation
  static_memory_size = static_memory_size + dble(NGLLX)*dble(NGLLY)*dble(NGLLZ)*NSPEC_OUTER_CORE_ROTATION*2.d0*dble(CUSTOM_REAL)

  end subroutine memory_eval

