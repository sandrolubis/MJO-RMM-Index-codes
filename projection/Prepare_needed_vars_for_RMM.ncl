begin

 f=addfile("/pscratch/sd/s/slubis/CES_Models_Jay/HighResMIP_AGCM/highresSST-future/MPI-ESM1-2-XR/ua_day_MPI-ESM1-2-XR_highresSST-future_r1i1p1f1_gn_20150101-20501231_2.5_2.5.nc","r")
 U850=f->ua(0:13148,1,:,:) ; be careful choose level 850
 U250=f->ua(0:13148,4,:,:) ; be careful  choose level 250
 time=f->time(0:13148)
 lev=f->lev(:)
 ;print(lev)
 lat=f->lat
 lon=f->lon

delete(f)

 f=addfile("/pscratch/sd/s/slubis/CES_Models_Jay/HighResMIP_AGCM/highresSST-future/MPI-ESM1-2-XR/rlut_day_MPI-ESM1-2-XR_highresSST-future_r1i1p1f1_gn_20150101-20501231_2.5_2.5.nc","r")
 OLR=f->rlut(0:13148,:,:)
 
 printVarSummary(U850)
  printVarSummary(U250)
   printVarSummary(OLR)

;interpolate...
 guess     = 1                ; use zonal means
 is_cyclic = True            ; cyclic [global]
 nscan     = 1500           ; usually much less than this
 eps       = 1.e-2            ; variable dependent
 relc      = 0.6              ; relaxation coefficient
 opt       = 0                ; not used

 poisson_grid_fill(U850, is_cyclic, guess, nscan, eps, relc, opt)
 
 dims=dimsizes(U850)

; Assign attributes
 U850!0 = "time"
 U850!1 = "lat"
 U850!2 = "lon"

 U850&time = time
 U850&lat = lat
 U850&lon = lon

; Assign attributes
 U250!0 = "time"
 U250!1 = "lat"
 U250!2 = "lon"

 U250&time = time
 U250&lat = lat
 U250&lon = lon

; Assign attributes
 OLR!0 = "time"
 OLR!1 = "lat"
 OLR!2 = "lon"

 OLR&time = time
 OLR&lat = lat
 OLR&lon = lon


 printVarSummary(U850)
  printVarSummary(U250)
   printVarSummary(OLR)
   
 
 
 ; Store U850 into NetCDF file
;===================================================================
setfileoption("nc","Format","LargeFile")
diro = "./input/"       ; Output directory
filo = diro + "U850_day_MPI-ESM1-2-XR_ssp.regrid.nc"  ; Output file
system("/bin/rm -f " + filo)                          ; remove if exists
fout  = addfile (filo, "c")                           ; open output file
setfileoption(fout,"DefineMode",True)                 ; declare file definition mode

; Create global attributes of the file
fAtt        = True                                   ; assign file attributes
fAtt@title  = "U850"
fAtt@source_file   =  "MPI-ESM1-2-XR-daily-uv wind-GRIB"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc("date")
fileattdef(fout,fAtt)                                ; copy file attributes

; Predefine the coordinate variables and their dimensionality
dimNames = (/"time","lat","lon"/)
dimSizes = (/ dims(0), dims(1), dims(2)/)
dimUnlim = (/ False, False, False/)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

; Predefine the dimensionality of the variables to be written out
filevardef(fout, "time"  ,"double", "time" )
filevardef(fout, "lat"  ,"double", "lat" )
filevardef(fout, "lon"  ,"double", "lon" )
filevardef(fout, "U850"   ,"float", getvardims(U850))

; Copy attributes associated with each variable to the file
filevarattdef(fout,"time"  ,time)       ; copy tim attributes
filevarattdef(fout,"lat"  ,lat)         ; copy lat attributes
filevarattdef(fout,"lon"  ,lon)         ; copy lon attributes
filevarattdef(fout,"U850"  ,U850)       ; copy PS attributes

; Exit defining mode
setfileoption(fout,"DefineMode",False)

; Output only the data values
fout->time    = time
fout->lat     = lat
fout->lon     = lon
fout->U850    = U850

delete(fout)

; Store U250 into NetCDF file
;===================================================================
setfileoption("nc","Format","LargeFile")
diro = "./input/"       ; Output directory
filo = diro + "U250_day_MPI-ESM1-2-XR_ssp.regrid.nc"  ; Output file
system("/bin/rm -f " + filo)                          ; remove if exists
fout  = addfile (filo, "c")                           ; open output file
setfileoption(fout,"DefineMode",True)                 ; declare file definition mode

; Create global attributes of the file
fAtt        = True                                   ; assign file attributes
fAtt@title  = "U250"
fAtt@source_file   =  "MPI-ESM1-2-XR-daily-uv wind-GRIB"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc("date")
fileattdef(fout,fAtt)                                ; copy file attributes

; Predefine the coordinate variables and their dimensionality
dimNames = (/"time","lat","lon"/)
dimSizes = (/ dims(0), dims(1), dims(2)/)
dimUnlim = (/ False, False, False/)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

; Predefine the dimensionality of the variables to be written out
filevardef(fout, "time"  ,"double", "time" )
filevardef(fout, "lat"  ,"double", "lat" )
filevardef(fout, "lon"  ,"double", "lon" )
filevardef(fout, "U250"   ,"float", getvardims(U250))

; Copy attributes associated with each variable to the file
filevarattdef(fout,"time"  ,time)       ; copy tim attributes
filevarattdef(fout,"lat"  ,lat)         ; copy lat attributes
filevarattdef(fout,"lon"  ,lon)         ; copy lon attributes
filevarattdef(fout,"U250"  ,U250)       ; copy PS attributes

; Exit defining mode
setfileoption(fout,"DefineMode",False)

; Output only the data values
fout->time    = time
fout->lat     = lat
fout->lon     = lon
fout->U250    = U250

delete(fout)

; Store OLR into NetCDF file
;===================================================================
setfileoption("nc","Format","LargeFile")
diro = "./input/"       ; Output directory
filo = diro + "OLR_day_MPI-ESM1-2-XR_ssp.regrid.nc"   ; Output file
system("/bin/rm -f " + filo)                          ; remove if exists
fout  = addfile (filo, "c")                           ; open output file
setfileoption(fout,"DefineMode",True)                 ; declare file definition mode

; Create global attributes of the file
fAtt        = True                                   ; assign file attributes
fAtt@title  = "OLR"
fAtt@source_file   =  "MPI-ESM1-2-XR-daily-OLR-GRIB"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc("date")
fileattdef(fout,fAtt)                                ; copy file attributes

; Predefine the coordinate variables and their dimensionality
dimNames = (/"time","lat","lon"/)
dimSizes = (/ dims(0), dims(1), dims(2)/)
dimUnlim = (/ False, False, False/)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

; Predefine the dimensionality of the variables to be written out
filevardef(fout, "time"  ,"double", "time" )
filevardef(fout, "lat"  ,"double", "lat" )
filevardef(fout, "lon"  ,"double", "lon" )
filevardef(fout, "OLR"   ,"float", getvardims(OLR))

; Copy attributes associated with each variable to the file
filevarattdef(fout,"time"  ,time)       ; copy tim attributes
filevarattdef(fout,"lat"  ,lat)         ; copy lat attributes
filevarattdef(fout,"lon"  ,lon)         ; copy lon attributes
filevarattdef(fout,"OLR"  ,OLR)         ; copy PS attributes

; Exit defining mode
setfileoption(fout,"DefineMode",False)

; Output only the data values
fout->time    = time
fout->lat     = lat
fout->lon     = lon
fout->OLR     = OLR

delete(fout)
 
end
