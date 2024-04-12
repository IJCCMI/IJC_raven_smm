#this script makes vectors for all the landcover classes in NALCMS 2015
#for use on SMM model
#JWT August 2023

import arcpy
from arcpy.sa import *
base = 'Q:/GW/IJC0000IJC_CMI/IJCStMaryMilk/hydrology_twg/spatial/'
arcpy.env.workspace = base + "scratch/"
arcpy.env.overwriteOutput = True
arcpy.CheckOutExtension("Spatial")


#outer basin
outer_basin = base + "/outputs/SMM_outer_Boundary.shp"

#NALCMS landcover
nalcms = base + "/inputs/NALCMS/NA_NALCMS_landcover_2015v3_30m.tif"

#1 buffer watershed (1000m)
buff = "SMM_buffer.shp"
#arcpy.analysis.Buffer(outer_basin, buff, 1000)

#2 clip to nalcms to buffer of watershed
lc_clip = "nalcms_clipped.tif"
#arcpy.management.Clip(nalcms, "", lc_clip, buff)

#3 reclassify important features of raster
#wetlands, water, glaciers
#leaving farmland out, it will still be differentiated by other hru, should be good enough resolution
reclass = "nalcms_reclass.tif"
#outreclass = Reclassify(lc_clip, "Value", RemapRange([[1,13,"NODATA"], [14,14,100], [15,15,"NODATA"], [16,16, "NODATA"], [17,17,"NODATA"], [18,18,300], [19,19,400]]))
#outreclass.save(reclass)

#4 vectorize reclassified raster
vec_lc = "nalcms_reclass.shp"
#arcpy.conversion.RasterToPolygon(reclass, vec_lc, "SIMPLIFY", "Value")

#5 project polygon
vec_lc_proj = "nalcms_reclass_proj.shp"
#arcpy.management.Project(vec_lc, vec_lc_proj, outer_basin)

#6 clip to outer basin
vec_lc_clip = "nalcms_for_hrus.shp"
arcpy.Clip_analysis(vec_lc_proj, outer_basin, vec_lc_clip)

#7 add area attribute
arcpy.AddGeometryAttributes_management(vec_lc_clip, "AREA", "", "HECTARES")

#8 delete areas less than 5 ha in size
simp = "nalcms_simp_for_hrus.shp"
arcpy.management.CopyFeatures(vec_lc_clip, simp)
arcpy.MakeFeatureLayer_management(simp, "templayer.shp")
arcpy.SelectLayerByAttribute_management("templayer.shp", "NEW_SELECTION", '"POLY_AREA" < 5')
arcpy.management.DeleteFeatures("templayer.shp")
