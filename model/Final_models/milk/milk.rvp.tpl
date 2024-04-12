#-----------------------------------------------------------------
# Raven Properties file Template. Created by Raven v3.7 w/ netCDF
#-----------------------------------------------------------------
# all expressions of format *xxx* need to be specified by the user 
# all parameter values of format ** need to be specified by the user 
# soil, land use, and vegetation classes should be made consistent with user-generated .rvh file 
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# Soil Classes
#-----------------------------------------------------------------
:SoilClasses
  :Attributes, SAND , CLAY, ORGANIC
  :Units, frac, frac, frac
	TOPSOIL1,1,0,0
	SLOW_RES1,1,0,0
	FAST_RES1,1,0,0
	TOPSOIL2,1,0,0
	SLOW_RES2,1,0,0
	FAST_RES2,1,0,0
	TOPSOIL3,1,0,0
	SLOW_RES3,1,0,0
	FAST_RES3,1,0,0
:EndSoilClasses

#-----------------------------------------------------------------
# Land Use Classes
#-----------------------------------------------------------------
:LandUseClasses, 
  :Attributes,   IMPERM,    FOREST_COV, 
       :Units,     frac,          frac, 
  Crops,              0,         0.25, 
  Shrubgrass,         0,         0.25, 
  LeafForest,         0,            1,
  Needleforest,       0,            1, 
  Open,               0             0, 
:EndLandUseClasses

#-----------------------------------------------------------------
# Vegetation Classes
#-----------------------------------------------------------------
:VegetationClasses, 
  :Attributes,          MAX_HT,      MAX_LAI, MAX_LEAF_COND, 
       :Units,               m,         none,      mm_per_s, 
      Crops,                 4,            5,             5, 
      Shrubgrass,            4,            5,             5, 
      LeafForest,           15,            6,             5, 
      Needleforest,         15,            6,             5, 
      Open,                  0,            0,             0,
:EndVegetationClasses

#-----------------------------------------------------------------
# Soil Profiles
#-----------------------------------------------------------------
:SoilProfiles
     LAKE,    0
     ROCK,    0
     GLACIER, 0
		 SOIL_1,  3,TOPSOIL1,par_x01,FAST_RES1,0.33,SLOW_RES1,0.33
		 SOIL_2,  3,TOPSOIL2,par_x02,FAST_RES2,0.33,SLOW_RES2,0.33
		 SOIL_3,  3,TOPSOIL3,par_x03,FAST_RES3,0.33,SLOW_RES3,0.33
:EndSoilProfiles

#-----------------------------------------------------------------
# Global Parameters
#-----------------------------------------------------------------
:GlobalParameter          RAINSNOW_TEMP    par_x04 
:GlobalParameter            RAINSNOW_DELTA par_x05 
:GlobalParameter               SNOW_SWI    par_x06 
:GlobalParameter            TOC_MULTIPLIER 1 
:GlobalParameter   TIME_TO_PEAK_MULTIPLIER 1 
:GlobalParameter    GAMMA_SHAPE_MULTIPLIER 1 
:GlobalParameter    GAMMA_SCALE_MULTIPLIER 1 
:GlobalParameter        AVG_ANNUAL_RUNOFF  50
:GlobalParameter        ADIABATIC_LAPSE    par_x07
#-----------------------------------------------------------------
# Soil Parameters
#-----------------------------------------------------------------
:SoilParameterList
  :Parameters,        POROSITY,        HBV_BETA,  PET_CORRECTION,  FIELD_CAPACITY,        SAT_WILT, MAX_CAP_RISE_RATE,   MAX_PERC_RATE,  BASEFLOW_COEFF,      BASEFLOW_N, BASEFLOW_COEFF2, STORAGE_THRESHOLD, 
       :Units,               -,               -,               -,               -,               -,            mm/d,            mm/d,             1/d,               -,             1/d,              mm, 
    [DEFAULT],             0.4,         par_x08,         par_x11,         par_x14,         par_x17,         par_x20,         par_x21,         par_x22,         par_x26,         par_x27,         par_x30, 
    TOPSOIL1,         _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT, 
    FAST_RES1,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT, 
    SLOW_RES1,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT,        _DEFAULT, 
    TOPSOIL2,         _DEFAULT,         par_x09,         par_x12,         par_x15,         par_x18,        _DEFAULT,        _DEFAULT,         par_x23,        _DEFAULT,         par_x28,        _DEFAULT, 
    FAST_RES2,        _DEFAULT,         par_x09,         par_x12,         par_x15,         par_x18,        _DEFAULT,        _DEFAULT,         par_x23,        _DEFAULT,         par_x28,        _DEFAULT, 
    SLOW_RES2,        _DEFAULT,         par_x09,         par_x12,         par_x15,         par_x18,        _DEFAULT,        _DEFAULT,         par_x24,        _DEFAULT,         par_x28,        _DEFAULT, 
    TOPSOIL3,         _DEFAULT,         par_x10,         par_x13,         par_x16,         par_x19,        _DEFAULT,        _DEFAULT,         par_x25,        _DEFAULT,         par_x29,         par_x31, 
    FAST_RES3,        _DEFAULT,         par_x10,         par_x13,         par_x16,         par_x19,        _DEFAULT,        _DEFAULT,         par_x25,        _DEFAULT,         par_x29,         par_x31, 
    SLOW_RES3,        _DEFAULT,         par_x10,         par_x13,         par_x16,         par_x19,        _DEFAULT,        _DEFAULT,         par_x25,        _DEFAULT,         par_x29,         par_x31, 
:EndSoilParameterList

#-----------------------------------------------------------------
# Land Use Parameters
#-----------------------------------------------------------------
:LandUseParameterList
  :Parameters,     MELT_FACTOR,    DD_MELT_TEMP, MIN_MELT_FACTOR, HBV_MELT_ASP_CORR, HBV_MELT_FOR_CORR, REFREEZE_FACTOR, FOREST_SPARSENESS, HBV_MELT_GLACIER_CORR, HBV_GLACIER_KMIN, GLAC_STORAGE_COEFF,  HBV_GLACIER_AG,   LAKE_PET_CORR,	OW_PET_CORR,	LAKE_REL_COEFF,    PDMROF_B,       DEP_MAX, MAX_DEP_AREA_FRAC, PONDED_EXP, 
       :Units,          mm/d/k,            degC,          mm/d/k,                 -,                 -,          mm/d/k,                 -,           	        -,                -,      	      -,            1/mm,               -,             	  -,		   1/d,           -,            mm,                 -,          -, 
    [DEFAULT],         par_x32,         par_x36,               2,                 0,                 1,         par_x38,               0.5,        	  par_x39,            0.001,         	par_x40,               0,         par_x63,          par_x64,		  0.01,     par_x41,       par_x44,           par_x47,    par_x50, 
    Crops,            _DEFAULT,        _DEFAULT,        _DEFAULT,          _DEFAULT,          _DEFAULT,        _DEFAULT,          _DEFAULT,        	 _DEFAULT,         _DEFAULT,           _DEFAULT,        _DEFAULT,        _DEFAULT,         _DEFAULT,	      _DEFAULT,     par_x42,       par_x45,           par_x48,    par_x51, 
    Shrubgrass,       _DEFAULT,        _DEFAULT,        _DEFAULT,          _DEFAULT,          _DEFAULT,        _DEFAULT,          _DEFAULT,      	 _DEFAULT,         _DEFAULT,           _DEFAULT,        _DEFAULT,        _DEFAULT,         _DEFAULT,	      _DEFAULT,     par_x43,       par_x46,           par_x49,    par_x52, 
    Needleforest,      par_x33,         par_x37,        _DEFAULT,          _DEFAULT,          _DEFAULT,        _DEFAULT,          _DEFAULT,              _DEFAULT,         _DEFAULT,           _DEFAULT,        _DEFAULT,        _DEFAULT,         _DEFAULT, 	      _DEFAULT,    _DEFAULT,      _DEFAULT,          _DEFAULT,   _DEFAULT, 
    LeafForest,        par_x34,         par_x37,        _DEFAULT,          _DEFAULT,          _DEFAULT,        _DEFAULT,          _DEFAULT,        	 _DEFAULT,         _DEFAULT,           _DEFAULT,        _DEFAULT,        _DEFAULT,         _DEFAULT,	      _DEFAULT,    _DEFAULT,      _DEFAULT,          _DEFAULT,   _DEFAULT, 
    Open,              par_x35,        _DEFAULT,        _DEFAULT,          _DEFAULT,          _DEFAULT,        _DEFAULT,          _DEFAULT,              _DEFAULT,         _DEFAULT,           _DEFAULT,        _DEFAULT,        _DEFAULT,         _DEFAULT,	      _DEFAULT,    _DEFAULT,      _DEFAULT,          _DEFAULT,   _DEFAULT, 
:EndLandUseParameterList

#-----------------------------------------------------------------
# Vegetation Parameters
#-----------------------------------------------------------------
:VegetationParameterList
  :Parameters,  RAIN_ICEPT_PCT,  SNOW_ICEPT_PCT,     SAI_HT_RATIO,    MAX_CAPACITY, MAX_SNOW_CAPACITY, 
       :Units,               -,               -,             mm/d,              mm,                mm,
    [DEFAULT],         par_x53,         par_x56,                2,         par_x59,           par_x61, 
    Crops,            _DEFAULT,        _DEFAULT,         _DEFAULT,        _DEFAULT,          _DEFAULT, 
    Shrubgrass,        par_x54,         par_x57,         _DEFAULT,        _DEFAULT,          _DEFAULT,
    Needleforest,      par_x55,         par_x58,                4,         par_x60,           par_x62, 
    LeafForest,        par_x55,         par_x58,                4,         par_x60,           par_x62, 
    Open,                    0,        _DEFAULT,                2,               0,                 0, 
:EndVegetationParameterList
:SeasonalRelativeLAI
  [DEFAULT], 1,1,1,1,1,1,1,1,1,1,1,1
:EndSeasonalRelativeLAI
:SeasonalRelativeHeight
  [DEFAULT], 1,1,1,1,1,1,1,1,1,1,1,1
:EndSeasonalRelativeHeight

# ----Channel profiles-------------------------
:RedirectToFile channel_sections.rvp