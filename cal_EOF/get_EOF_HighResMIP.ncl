;
;***********************************************************
; Combined EOFs
;***********************************************************
;;
;;      The following are automatically loaded from 6.2.0 onward
;;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
;;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

undef("read_rename")
function read_rename(f[1]:file, varName[1]:string       \
                    ,iStrt[1]:integer, iLast[1]:integer \
                    ,latS[1]:numeric , latN[1]:numeric  )
; Utility to force specific named dimensions
; This is done for historical reasons (convenience)
begin
   ;print(model)
   work    = f->$varName$(iStrt:iLast,{latS:latN},:)   ; (time,lat,lon)
   work!0  = "time"                                    ; CAM model names
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

   pltDir  = "./"                             ; plot directory
   pltType = "png" 
   pltName = "mjoclivar14_"+expname   

   diri    = "../anom/"                             ; input directory

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
;   lat  = f->lat
;   lon  = f->lon

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

;   print(OLR)

   dimw    = dimsizes( work )
   ntim    = dimw(0)
   nlat    = dimw(1)
   mlon    = dimw(2)
   delete(work)

   lon     = OLR&lon                                          
   time    = OLR&time                         
   date    = cd_calendar(time, -2)            ; yyyymmdd

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
; Compute **combined** EOF; Sign of EOF is arbitrary
;************************************************
  eof_cdata    = eofunc(cdata   , neof, False)      ; (neof,3*mlon)
;  print("==============")
;  printVarSummary(eof_cdata)
;  printMinMax(eof_cdata, True)

  eof_ts_cdata = eofunc_ts(cdata,eof_cdata,False)   ; (neof,3*ntim)
;  print("==============")                                  
;  printVarSummary(eof_ts_cdata)
;  printMinMax(eof_ts_cdata, True)

;************************************************
; For clarity, explicitly extract each variable. Create time series 
;************************************************

  nvar = 3  ; "OLR", "U850", "U250"
  ceof = new( (/nvar,neof,mlon/), typeof(cdata), getFillValue(cdata))

  do n=0,neof-1
     ceof(0,n,:) = eof_cdata(n,0:mlon-1)      ; OLR
     ceof(1,n,:) = eof_cdata(n,mlon:2*mlon-1) ; U850
     ceof(2,n,:) = eof_cdata(n,2*mlon:)       ; U250
  end do

  ceof!0   = "var"
  ceof!1   = "eof"
  ceof!2   = "lon"   
  ceof&lon =  OLR&lon

  ceof_ts        = new( (/nvar,neof,ntim/), typeof(cdata), getFillValue(cdata))
  ceof_ts(0,:,:) = eofunc_ts_Wrap( OLR(lon|:,time|:),ceof(0,:,:),False)   ; (0,neof,ntim)
  ceof_ts(1,:,:) = eofunc_ts_Wrap(U850(lon|:,time|:),ceof(1,:,:),False)   ; (1,neof,ntim)
  ceof_ts(2,:,:) = eofunc_ts_Wrap(U250(lon|:,time|:),ceof(2,:,:),False)   ; (2,neof,ntim)

;**********************************************t*
; Add code contributed by Marcus N. Morgan, Florida Institute of Technology; Feb 2015
; Calculate % variance (pcv_ )accounted for by OLR, U850 and U250
;************************************************

    pcv_eof_OLR  = new(neof,typeof(ceof))
    pcv_eof_U850 = new(neof,typeof(ceof))
    pcv_eof_U250 = new(neof,typeof(ceof))
      
    do n=0,neof-1
       pcv_eof_OLR(n)  = avg((ceof(0,n,:)*sqrt(ceof@eval(n)))^2)*100
       pcv_eof_U850(n) = avg((ceof(1,n,:)*sqrt(ceof@eval(n)))^2)*100
       pcv_eof_U250(n) = avg((ceof(2,n,:)*sqrt(ceof@eval(n)))^2)*100
     ;;print("pcv: neof="+(n+1)+":  "+pcv_eof_OLR(n)+"  "+pcv_eof_U850(n)+"  "+pcv_eof_U250(n))
    end do

;************************************************
; Change sign of EOFs for spatial structures of PC1 and PC2 
; to represent convection over the tropical Indian Ocean and the tropical western Pacific Ocean, respectively 
; (Ad hoc approach) 
;************************************************
  do_flip1 = 0
  do_flip2 = 0
  do_swip = 0
  imax_OLR_eof1   = maxind(ceof(0,0,:))
  imax_OLR_eof2   = maxind(ceof(0,1,:))
  lonmax_eof1 = ceof&lon(imax_OLR_eof1)      ; longitude of max value (i.e. suppressed convection)
  lonmax_eof2 = ceof&lon(imax_OLR_eof2)

  imin_OLR_eof1   = minind(ceof(0,0,:))
  imin_OLR_eof2   = minind(ceof(0,1,:))
  lonmin_eof1 = ceof&lon(imin_OLR_eof1)      ; longitude of max value (i.e. suppressed convection)
  lonmin_eof2 = ceof&lon(imin_OLR_eof2)

  if (lonmin_eof1.ge.60 .and. lonmin_eof1.le.120 .and. lonmin_eof2.ge.120 .and. lonmin_eof2.le.200) then
    print("no change") 
  else if (lonmin_eof1.ge.60 .and. lonmin_eof1.le.120 .and. lonmax_eof2.ge.120 .and. lonmax_eof2.le.200) then
     do_flip2 = 1
  else if (lonmin_eof1.ge.120 .and. lonmin_eof1.le.130 .and. lonmax_eof2.ge.140 .and. lonmax_eof2.le.200) then
     do_flip2 = 1
  else if  (lonmax_eof1.ge.60 .and. lonmax_eof1.le.120 .and. lonmin_eof2.ge.120 .and. lonmin_eof2.le.200) then
     do_flip1 = 1
  else if (lonmax_eof1.ge.60 .and. lonmax_eof1.le.120 .and. lonmax_eof2.ge.110 .and. lonmax_eof2.le.200) then
    do_flip1 = 1
    do_flip2 = 1
  else if (lonmin_eof1.ge.120 .and. lonmin_eof1.le.200 .and. lonmin_eof2.ge.60 .and. lonmin_eof2.le.120) then
    do_swip = 1
  else if (lonmin_eof1.ge.120 .and. lonmin_eof1.le.200 .and. lonmax_eof2.ge.60 .and. lonmax_eof2.le.120) then
    do_flip2 = 1
    do_swip =1
  else if (lonmax_eof1.ge.120 .and. lonmax_eof1.le.200 .and. lonmin_eof2.ge.60 .and. lonmin_eof2.le.120) then
    do_flip1 = 1
    do_swip = 1
  else if (lonmax_eof1.ge.120 .and. lonmax_eof1.le.200 .and. lonmax_eof2.ge.60 .and. lonmax_eof2.le.120) then
    do_flip1 = 1
    do_flip2 = 1
    do_swip = 1
  else
    print("exception meet")
  end if
  end if
  end if 
  end if
  end if
  end if
  end if
  end if
  end if
  if (do_flip1.eq.1) then  ; Change the sign of EOF1 
      ceof(:,0,:)       = -ceof(:,0,:)                  ; if OLR is positive
      ceof_ts(:,0,:)    = -ceof_ts(:,0,:)               ;  over the tropical Indian Ocean
      eof_cdata(0,:)    = -eof_cdata(0,:)
      eof_ts_cdata(0,:) = -eof_ts_cdata(0,:)
  end if

  if (do_flip2.eq.1) then
      ceof(:,1,:)       = -ceof(:,1,:)                   ; if OLR is positive 
      ceof_ts(:,1,:)    = -ceof_ts(:,1,:)                ; over the tropical western Pacific Ocean
      eof_cdata(1,:)    = -eof_cdata(1,:)
      eof_ts_cdata(1,:) = -eof_ts_cdata(1,:)
  end if


  if (do_swip.eq.1) then  ; swip eof1 and eof2
  
      tmp_8      = ceof@pcvar(0)
      tmp_9      = ceof@pcvar(1) 

      tmp_1       = ceof(:,0,:)                 
      tmp_2       = ceof_ts(:,0,:)               
      tmp_3       = eof_cdata(0,:)
      tmp_4       = eof_ts_cdata(0,:)
     
      tmp_5       = pcv_eof_U250(0) 
      tmp_6       = pcv_eof_U850(0)
      tmp_7       = pcv_eof_OLR(0)
      
      ceof(:,0,:)       = ceof(:,1,::)                
      ceof_ts(:,0,:)    = ceof_ts(:,1,:)              
      eof_cdata(0,:)    = eof_cdata(1,:)
      eof_ts_cdata(0,:) = eof_ts_cdata(1,:)
      pcv_eof_U250(0) = pcv_eof_U250(1)
      pcv_eof_U850(0) = pcv_eof_U850(1)
      pcv_eof_OLR(0)  = pcv_eof_OLR(1)

      ceof(:,1,:)       = tmp_1
      ceof_ts(:,1,:)    = tmp_2
      eof_cdata(1,:)    = tmp_3
      eof_ts_cdata(1,:) = tmp_4
      pcv_eof_U250(1) = tmp_5
      pcv_eof_U850(1) = tmp_6
      pcv_eof_OLR(1)  = tmp_7

      ceof@pcvar(0) = tmp_9
      ceof@pcvar(1) = tmp_8
  end if


;  print("==============")
;  printVarSummary(eof_cdata)
;  printMinMax(eof_cdata, True)

;************************************************
; Compute cross correlation of each variable's EOF time series at zero-lag
;************************************************
  r_OLR_U850  = escorc(ceof_ts(0,:,:) , ceof_ts(1,:,:) )  ; (neof)
  r_OLR_U250  = escorc(ceof_ts(0,:,:) , ceof_ts(2,:,:) )
  r_U850_U250 = escorc(ceof_ts(1,:,:) , ceof_ts(2,:,:) )

;  print("==============")
;  do n=0,neof-1
;     print("neof="+n \
;          +"  r_OLR_U850=" +sprintf("%4.3f",r_OLR_U850(n))  \
;          +"  r_OLR_U250=" +sprintf("%4.3f",r_OLR_U250(n))  \
;          +"  r_U850_U250="+sprintf("%4.3f",r_U850_U250(n)) )
;  end do
; print("==============")

;************************************************
; Compute cross correlation of the multivariate EOF; EOF 1 vs EOF 2
;************************************************

  mxlag     = 25
  rlag_01   = esccr(eof_ts_cdata(0,:),eof_ts_cdata(1,:), mxlag)   ; (N,mxlag+1)
  rlag_10   = esccr(eof_ts_cdata(1,:),eof_ts_cdata(0,:), mxlag)   ; (N,mxlag+1)
  ccr_12    = new ( (/2*mxlag+1/), float)    

  ccr_12(mxlag:)    = rlag_10(0:mxlag)   
  ccr_12(0:mxlag)   = rlag_01(::-1)       ; reverse order
;;print(ccr_12)


;************************************************
; Normalize the multivariate EOF 1&2 component time series
; Compute (PC1^2+PC2^2): values > 1 indicate "strong" periods
;************************************************
; stdev is already (by method) 1 no need to normalized (wenyu)
  eof_ts_cdata(0,:) = eof_ts_cdata(0,:)/stddev(eof_ts_cdata(0,:))
  eof_ts_cdata(1,:) = eof_ts_cdata(1,:)/stddev(eof_ts_cdata(1,:))

; print(stddev(eof_ts_cdata(0,:)))
; print(stddev(eof_ts_cdata(1,:)))
  mjo_ts_index      = eof_ts_cdata(0,:)^2 + eof_ts_cdata(1,:)^2 
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
  mjo_ts_index@info      = "(PC1^2 + PC2^2)" 

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

  diro = "./"
  filo = "MJO_PC_"+expname+".nc"
  system("/bin/rm -f "+diro+filo)   ; remove any pre-existing file
  ncdf = addfile(diro+filo,"c")     ; open output netCDF file
                                    ; make time an UNLIMITED dimension 
  filedimdef(ncdf,"time",-1,True)   ; recommended  for most applications
                                    ; output variables directly
  ncdf->MJO_INDEX = mjo_ts_index    
  ncdf->PC1       = PC1     
  ncdf->PC2       = PC2     

;************************************************
; Write EOF results to netCDF for use in another example.
;************************************************

  EOF1_OLR           = ceof(0,0,:)
  EOF1_OLR!0         = "lon"
  EOF1_OLR&lon      =  lon
  EOF1_OLR@long_name = "1st EOF for OLR"

  EOF2_OLR           = ceof(0,1,:)
  EOF2_OLR!0         = "lon"
  EOF2_OLR&lon      =  lon
  EOF2_OLR@long_name = "2nd EOF for OLR"

  EOF1_U850           = ceof(1,0,:)
  EOF1_U850!0         = "lon"
  EOF1_U850&lon      =  lon
  EOF1_U850@long_name = "1st EOF for U850"

  EOF2_U850           = ceof(1,1,:)
  EOF2_U850!0         = "lon"
  EOF2_U850&lon      =  lon
  EOF2_U850@long_name = "2nd EOF for U850"

  EOF1_U250           = ceof(2,0,:)
  EOF1_U250!0         = "lon"
  EOF1_U250&lon      =  lon
  EOF1_U250@long_name = "1st EOF for U250"

  EOF2_U250           = ceof(2,1,:)
  EOF2_U250!0         = "lon"
  EOF2_U250&lon      =  lon
  EOF2_U250@long_name = "2nd EOF for U250"

  diro = "./"
  filo = "MJO_EOF_"+expname+".nc"
  system("/bin/rm -f "+diro+filo)   ; remove any pre-existing file
  ncdf = addfile(diro+filo,"c")     ; open output netCDF file
                                    ; make time an UNLIMITED dimension
  ncdf->EOF1_OLR       = EOF1_OLR
  ncdf->EOF2_OLR       = EOF2_OLR
  ncdf->EOF1_U850      = EOF1_U850
  ncdf->EOF2_U850      = EOF2_U850
  ncdf->EOF1_U250      = EOF1_U250
  ncdf->EOF2_U250      = EOF2_U250
 

 end
