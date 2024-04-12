# script makes the HRUs for NLG model using Arcpy
#updated by GMWB from Similkameen script 2021-06-14

import arcpy
from arcpy.sa import *
base = 'Q:/GW/IJC0000IJC_CMI/IJCStMaryMilk/hydrology_twg/spatial/'
arcpy.env.workspace = base + "scratch/"
arcpy.env.overwriteOutput = True
arcpy.CheckOutExtension("Spatial")


#step 1 project subs, streams, DEM, LC, soils to same as wbs
wbs = base + '/inputs/TGF_smm/tgf_waterbodies.shp'
tgf = base + "/inputs/smm_tgf_modified/smm_cat.shp"
riv = base + "/inputs/smm_tgf_modified/smm_riv.shp"

tgf_proj = 'smm_cat_proj.shp'
#arcpy.management.Project(tgf, tgf_proj, wbs)

riv_proj = 'smm_riv_proj.shp'
#arcpy.management.Project(riv, riv_proj, wbs)


dem = base + "/inputs/3-gistool/MERIT_Hydro/MERIT_Hydro_elv.tif"
demproj = base + "/outputs/raster/smm_merit_dem.tif"
#arcpy.ProjectRaster_management(dem, demproj, wbs,\
 #                               "BILINEAR")


#step 1a (MANUAL to fix cypress lake routing (August 2023 by JWT)
#Done on smm_cat_edit.shp and smm_riv_edit.shp
#(copied from smm_cat_proj and smm_riv_proj)

#1
#remove all fields except hru_nhm, seg_nhm, HUC04, Shape_Leng and Shape_Area from smm_cat_proj)
#remove all fields except seg_nhm, ds_seg_nhm, seg_slope, LENGTH from smm_riv_proj 

#2
#clip basins (hru_nhm):
#114352
#114359
#114349
#114351
#With cypress lake polygon from water bodies shapefile (OBJECTID 156)

#3 - New subbasin cypress lake named:
#Hru_nhm = 99999
#Seg_nhm = 58453
#Channel length in new subbasin not relevant

#3 - adjust seg_nhm on newly clipped basins:
#114351, change seg_nhm from 58453 to 58651

#4 - adjust downstream (ds_seg_nhm) on streams
#58655, change ds_seg_nhm from 58651 to 58453

tgf_edit = 'smm_cat_edit.shp'
riv_edit = 'smm_riv_edit.shp'


#step 2 create 200 m contours from DEM
cont_in = "Contours_200m.shp"
#Contour(demproj, cont_in, 200, 0)


#step 3 create full outer basin
outer_basin = base + '/outputs/SMM_outer_Boundary.shp'
#arcpy.Dissolve_management(tgf_proj, outer_basin)


#step 4 clip contours, streams and waterbodies with outer basin
clipped_contour = "Contours_200m_clipped.shp"
#arcpy.Clip_analysis(cont_in, outer_basin, clipped_contour)


clipped_str = 'clipped_streams_R1.shp'
arcpy.Clip_analysis(riv_edit, outer_basin, clipped_str)


clipped_wbs = 'clipped_wbs.shp'
#arcpy.Clip_analysis(wbs, outer_basin, clipped_wbs)


#step 5 add length to streams and join to subbasins
arcpy.AddGeometryAttributes_management(clipped_str, "LENGTH", "KILOMETERS", "")

subs = base + 'outputs/smm_subbasins_R1.shp'
str_data = 'clipped_streams_R1.dbf'
arcpy.CopyFeatures_management(tgf_edit, subs)
arcpy.JoinField_management(subs, 'seg_nhm', str_data, 'seg_nhm')
arcpy.AddGeometryAttributes_management(subs, "AREA", "", "HECTARES")



#step 7 convert contours to polygons
cont_out = 'contour_poly.shp'
#arcpy.FeatureToPolygon_management([clipped_contour, outer_basin], cont_out, "", "NO_ATTRIBUTES") 


#step 8 union the basins, the clipped contours, waterbodies
hrurough = 'smm_hrus_rough_r1.shp'
lc = 'nalcms_simp_for_hrus.shp'
arcpy.Union_analysis([subs, lc, cont_out], hrurough)

# #step 8
# #calculate area of each hru
arcpy.AddGeometryAttributes_management(hrurough, "AREA", "", "HECTARES")

# #step 9
# #then eliminate slivers (< 1 ha) would normally do 5 but one subbasin is about 1 ha
hru = base + 'outputs/smm_hrus_R2.shp'
arcpy.MakeFeatureLayer_management(hrurough, 'templayer.shp')

arcpy.SelectLayerByAttribute_management('templayer.shp', "NEW_SELECTION", 
                                       '"POLY_AREA" < 1')
arcpy.Eliminate_management('templayer.shp', hru, "LENGTH")

arcpy.AddGeometryAttributes_management(hru, "AREA", "", "HECTARES")


#this reduces hrus from 3414 to 2342
#for some reason still 8 slivers left over
#these will be removed in RavenR function to decrease hrus



