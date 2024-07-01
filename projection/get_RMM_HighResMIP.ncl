
undef("read_rename")
function read_rename(f[1]:file, varName[1]:string       \
                    ,iStrt[1]:integer, iLast[1]:integer \
                    ,latS[1]:numeric , latN[1]:numeric  )
; Utility to force specific named dimensions
; This is done for historical reasons (convenience) 
begin
   work    = f->$varName$(iStrt:iLast,{latS:latN},:)   ; (time,lat,lon)
   work!0  = "time"                                  
   work!1  = "lat"
   work!2  = "lon"
   return(work)
end

; =========================>  MAIN  <==============================
begin


model="MPI-ESM1-2-XR"
expname="ssp"
ymdStrt=20150101 
ymdLast=20501231

   neof    =  2

   latS    = -15
   latN    =  15

   yrStrt  = ymdStrt/10000
   yrLast  = ymdLast/10000

   pltDir  = "./plot/"                             ; plot directory
   pltType = "png" 
   pltName = "mjoclivar14_"+model+"_"+expname+"_baseonREOF"   

   diri    = "./anom/"                     ; input directory

   filOLR  = "OLR.day.anomalies."+yrStrt+"-"+yrLast+".nc"
   filU250 = "U250.day.anomalies."+yrStrt+"-"+yrLast+".nc"
   filU850 = "U850.day.anomalies."+yrStrt+"-"+yrLast+".nc"

;************************************************
; create BandPass Filter
;************************************************
  ihp      = 2                             ; bpf=>band pass filter
  nWgt     = 201
  sigma    = 1.0                           ; Lanczos sigma
  fca      = 1./100.
  fcb      = 1./20.
  wgt      = filwgts_lanczos (nWgt, ihp, fca, fcb, sigma )

;***********************************************************
; Find the indices corresponding to the start/end times
;***********************************************************
   f       = addfile (diri+filOLR , "r")                         
   TIME    = f->time                          ; days since ...

   YMD     = cd_calendar(TIME, -2)            ; entire (time,6)

   iStrt   = ind(YMD.eq.ymdStrt)              ; index start
   iLast   = ind(YMD.eq.ymdLast)              ; index last 
   delete([/ TIME, YMD /])

;***********************************************************
; Read anomalies
;***********************************************************

   work    = read_rename(f,"OLR_anom_sm",iStrt,iLast,latS,latN) ; (time,lat,lon) 
   OLR     = dim_avg_n_Wrap(work, 1)                         ; (time,lon)

   f       = addfile (diri+filU850 , "r")                         
   work    = read_rename(f,"U850_anom_sm",iStrt,iLast,latS,latN) ; (time,lat,lon) 
   U850    = dim_avg_n_Wrap(work, 1)          ; (time,lon)

   f       = addfile (diri+filU250 , "r")                         
   work    = read_rename(f,"U250_anom_sm",iStrt,iLast,latS,latN) ; (time,lat,lon) 
   U250    = dim_avg_n_Wrap(work, 1)          ; (time,lon)

   dimw    = dimsizes( work )
   ntim    = dimw(0)
   nlat    = dimw(1)
   mlon    = dimw(2)
   delete(work)

   lon     = OLR&lon                                          
   time    = OLR&time                         
   date    = cd_calendar(time, -2)            ; yyyymmdd
   
   printVarSummary(OLR)
      printVarSummary(U250)
         printVarSummary(U850)
   

;************************************************
; Apply the band pass filter to the original anomalies
;************************************************
   OLR   = wgt_runave_n_Wrap ( OLR, wgt, 0, 0) ; (time,lon)
   U850  = wgt_runave_n_Wrap (U850, wgt, 0, 0)
   U250  = wgt_runave_n_Wrap (U250, wgt, 0, 0)

;************************************************
; remove temporal means of band pass series: *not* necessary 
;************************************************
   OLR   = dim_rmvmean_n( OLR, 0)              ; (time,lon)
   U850  = dim_rmvmean_n(U850, 0)
   U250  = dim_rmvmean_n(U250, 0)

;************************************************
; Compute the temporal variance at each lon
;************************************************
   var_OLR  = dim_variance_n_Wrap( OLR, 0)     ; (lon)
   var_U850 = dim_variance_n_Wrap(U850, 0)
   var_U250 = dim_variance_n_Wrap(U250, 0)

;************************************************
; Compute the zonal mean of the temporal variance
;************************************************
  zavg_var_OLR  = dim_avg_n_Wrap( var_OLR , 0)     
  zavg_var_U850 = dim_avg_n_Wrap( var_U850, 0)
  zavg_var_U250 = dim_avg_n_Wrap( var_U250, 0)

;************************************************
; Normalize by sqrt(avg_var*)
;************************************************
  OLR   =  OLR/sqrt(zavg_var_OLR )          ; (time,lon)
  U850  = U850/sqrt(zavg_var_U850)
  U250  = U250/sqrt(zavg_var_U250)

;************************************************
; Combine the normalized data into one variable
;************************************************
  cdata     = new ( (/3*mlon,ntim/), typeof(OLR), getFillValue(OLR))
  do ml=0,mlon-1
     cdata(ml       ,:) = (/  OLR(:,ml) /)
     cdata(ml+  mlon,:) = (/ U850(:,ml) /)
     cdata(ml+2*mlon,:) = (/ U250(:,ml) /)
  end do

;************************************************
; Read in reanalysis EOFs
;************************************************

  eof_cdata = new( (/neof,3*mlon/), typeof(cdata), getFillValue(cdata))

   f       = addfile ("./OBS_EOFs/MJO_EOF_historical.nc", "r")  ; dont change this
   EOF1_OLR    = f->EOF1_OLR
   EOF2_OLR    = f->EOF2_OLR
   EOF1_U850   = f->EOF1_U850
   EOF2_U850   = f->EOF2_U850
   EOF1_U200   = f->EOF1_U200
   EOF2_U200   = f->EOF2_U200

   eof_cdata(0,0:mlon-1) = EOF1_OLR
   eof_cdata(0,mlon:2*mlon-1) = EOF1_U850
   eof_cdata(0,2*mlon:) = EOF1_U200

   eof_cdata(1,0:mlon-1) = EOF2_OLR
   eof_cdata(1,mlon:2*mlon-1) = EOF2_U850
   eof_cdata(1,2*mlon:) = EOF2_U200

;  print("==============")
;  printVarSummary(eof_cdata)
;  printMinMax(eof_cdata, True)

;************************************************
; compute PC1 and PC2
;************************************************

  eof_ts_cdata = eofunc_ts(cdata,eof_cdata,False)   ; (neof,3*ntim) ; only do projection to the observed EOF pattern!
;  print("==============")
;  printVarSummary(eof_ts_cdata)
;  printMinMax(eof_ts_cdata, True)

;************************************************
; Normalize the multivariate EOF 1&2 component time series
; Compute (PC1^2+PC2^2): values > 1 indicate "strong" periods
;************************************************
; stdev is already (by method) 1 no need to normalized (wenyu)
  eof_ts_cdata(0,:) = eof_ts_cdata(0,:)/stddev(eof_ts_cdata(0,:))
  eof_ts_cdata(1,:) = eof_ts_cdata(1,:)/stddev(eof_ts_cdata(1,:))


;************************************************
  mjo_ts_index      = (eof_ts_cdata(0,:)^2 + eof_ts_cdata(1,:)^2)^(0.5) 
  mjo_ts_index_smt  = runave(mjo_ts_index, 91, 0) ; 91-day running mean

  nGood   = num(.not.ismissing(mjo_ts_index))     ; # non-missing
  nStrong = num(mjo_ts_index .ge. 1.0)
;  print("nGood="+nGood+"   nStrong="+nStrong+"   nOther="+(nGood-nStrong))

;************************************************
; Write PC results to netCDF for use in another example.
;************************************************
  mjo_ts_index!0    = "time"
  mjo_ts_index&time = time 
  mjo_ts_index@long_name = "MJO PC INDEX" 
  mjo_ts_index@info      = "(PC1^2 + PC2^2)^(0.5)" 

  PC1           = eof_ts_cdata(0,:)
  PC1!0         = "time"
  PC1&time      =  time
  PC1@long_name = "PC1"
  PC1@info      = "PC1/stddev(PC1)"

  PC2           = eof_ts_cdata(1,:)
  PC2!0         = "time"
  PC2&time      =  time
  PC2@long_name = "PC2"
  PC2@info      = "PC2/stddev(PC2)"

  diro = "./final_output/"
  filo = "MJO_PC_"+expname+"_baseonREOF.nc"
  system("/bin/rm -f "+diro+filo)   ; remove any pre-existing file
  ncdf = addfile(diro+filo,"c")     ; open output netCDF file
                                    ; make time an UNLIMITED dimension 
  filedimdef(ncdf,"time",-1,True)   ; recommended  for most applications
                                    ; output variables directly
  ncdf->MJO_INDEX = mjo_ts_index    
  ncdf->PC1       = PC1     
  ncdf->PC2       = PC2     

 end
