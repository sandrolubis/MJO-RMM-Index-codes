begin

model="MPI-ESM1-2-XR"
expname="ssp"
ymdStrt=20150101 
ymdLast=20501231

;******************************************************
; User specifications
;******************************************************
   NC      = True                            ; create netCDF?       
   PLOT    = False                             ; sample plots?

  if (expname.eq."historical") then
     expdir = "hist"
  else
     expdir = "ssp"
  end if
   yrStrt  = ymdStrt/10000
   yrLast  = ymdLast/10000
  
   nhar    = 3                                ; number of fourier comp      

   diri    = "./input/"

vNames = (/"OLR","U850","U250"/)
nvar = dimsizes(vNames)
do i =0, nvar-1
   vName = vNames(i)
   print(vName)
   if (vName.eq."OLR") then
      var     = "OLR"                            ; name of file
      fili    = var+"_day_"+model+"_"+expname+".regrid.nc"               ; input file
   end if
   if (vName.eq."U850") then
      var     = "U850"
      fili    = var+"_day_"+model+"_"+expname+".regrid.nc"               ; input file
   end if
   if (vName.eq."U250") then
      var     = "U250"
      fili    = var+"_day_"+model+"_"+expname+".regrid.nc"               ; input file
   end if


   if (NC) then
       diro= "./anom/"         ; output dir
       filo= vName+".day.anomalies."+yrStrt+"-"+yrLast+".nc"  ; output file  
   end if

   if (PLOT) then
       wksType = "png"                        ; send graphics to PNG file
       wksName = "mjoclivar"                  ; "mjo."+yrStrt+"_"+yrLast
   end if

;***********************************************************
; Read user specified time and create required yyyyddd                    
;***********************************************************
   f       = addfile (diri+fili , "r")                          

   time    = f->time                          ; all times on file
   ymd     = cd_calendar(time, -2)            ; yyyymmdd
   iStrt   = ind(ymd.eq.ymdStrt)              ; index start
   iLast   = ind(ymd.eq.ymdLast)              ; index last 
   print(iStrt)
   print(iLast)
   delete(time)
   delete(ymd)

;***********************************************************
; Read user specified time and create required yyyyddd                    
;***********************************************************
   time    = f->time(iStrt:iLast)             ; time:units = "hours since"
   TIME    = cd_calendar(time, 0)             ; type float 
   year    = floattointeger( TIME(:,0) )
   month   = floattointeger( TIME(:,1) )
   day     = floattointeger( TIME(:,2) ) 
   ddd     = day_of_year(year, month, day) 
   yyyyddd = year*1000 + ddd                  ; needed for input

;***********************************************************
; Read data: short2flt                                     
;*********************************************************** 
   if ((var.eq."pr") .or. (var.eq."rlut")) then
     x       =  short2flt( f->$var$(iStrt:iLast,:,:) )    ; convert to float
   else
     x       =  short2flt( f->$var$(iStrt:iLast,:,:) )    ; convert to float 
   end if
;   printVarSummary( x ) 

;***********************************************************
; Compute daily climatology: raw and then 'smoothed'  
;***********************************************************
   xClmDay = clmDayTLL(x, yyyyddd)     ; daily climatology at each grid point
;   printVarSummary(xClmDay)            

;***********************************************************
; Compute smoothed daily climatology using 'nhar' harmonics
;***********************************************************
   xClmDay_sm = smthClmDayTLL(xClmDay, nhar)
;   printVarSummary(xClmDay_sm)

;***********************************************************
; Compute daily anomalies using raw and smoothed climatologies
;***********************************************************
    xAnom      = calcDayAnomTLL (x, yyyyddd, xClmDay)     
;    printVarSummary(xAnom)
;    printMinMax(xAnom, True)

    xAnom_sm   = calcDayAnomTLL (x, yyyyddd, xClmDay_sm)     
    xAnom_sm@long_name = "Anomalies from Smooth Daily Climatology"
;    printVarSummary(xAnom_sm)
;    printMinMax(xAnom_sm, True)

    delete( x )    ; no longer needed


;***********************************************************
; Create netCDF: convenience use 'simple' method
;***********************************************************

    dimx   = dimsizes(xAnom)
    ntim   = dimx(0)
    nlat   = dimx(1)
    mlon   = dimx(2)

    if (NC) then

        lat    = f->lat
        lon    = f->lon

        system("/bin/rm -f "+diro+filo)      ; rm any pre-exist file, if any
        fnc    = addfile (diro+filo, "c")

        filAtt = 0
        filAtt@title         = vName+": Daily Anomalies: "+yrStrt+"-"+yrLast  
	filAtt@source_file   = fili
        filAtt@creation_date = systemfunc("date")
        fileattdef( fnc, filAtt )         ; copy file attributes  

        setfileoption(fnc,"DefineMode",True)
        
        varNC      = vName+"_anom"
        varNC_sm   = vName+"_anom_sm"

        dimNames = (/"time", "lat", "lon"/)  
	dimSizes = (/ -1   ,  nlat,  mlon/) 
	dimUnlim = (/ True , False, False/)   
	filedimdef(fnc,dimNames,dimSizes,dimUnlim)

        filevardef(fnc, "time"  ,typeof(time),getvardims(time)) 
        filevardef(fnc, "lat"   ,typeof(lat) ,getvardims(lat)) 
        filevardef(fnc, "lon"   ,typeof(lon) ,getvardims(lon))
        filevardef(fnc, varNC   ,typeof(xAnom)   ,getvardims(xAnom))    
        filevardef(fnc, varNC_sm,typeof(xAnom)   ,getvardims(xAnom))    

        filevarattdef(fnc,"time"  ,time)                    ; copy time attributes
        filevarattdef(fnc,"lat"   ,lat)                     ; copy lat attributes
        filevarattdef(fnc,"lon"   ,lon)                     ; copy lon attributes
        filevarattdef(fnc,varNC   ,xAnom)                
        filevarattdef(fnc,varNC_sm,xAnom_sm)                

        fnc->time       = (/time/)     
        fnc->lat        = (/lat/)
        fnc->lon        = (/lon/)
        fnc->$varNC$    = (/xAnom   /)
        fnc->$varNC_sm$ = (/xAnom_sm/)
    end if
end do
end
