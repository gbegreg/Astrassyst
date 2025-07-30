unit uUtils;

interface
  uses System.SysUtils, system.Permissions, System.Math.Vectors, system.types, system.math, FMX.Platform
       {$IFDEF Android}
         , Androidapi.JNI.App, Androidapi.JNI.GraphicsContentViewText, Androidapi.Helpers
       {$ENDIF};

  procedure desactiverVeille;
  function DegDecToDMS( DegDec : Real ):String;
  function isInRange(value, min, max : integer): boolean;
  function getLangue:string;

  {$IFDEF Android}
  const
    CoarseLocationPermission = 'android.permission.ACCESS_COARSE_LOCATION';
    FineLocationPermission = 'android.permission.ACCESS_FINE_LOCATION';
    CameraPermission = 'android.permission.CAMERA';
  {$ENDIF}

implementation

procedure desactiverVeille;
begin
  {$IFDEF Android}
    TAndroidHelper.activity.getWindow.addFlags(TJWindowManager_LayoutParams.JavaClass.FLAG_KEEP_SCREEN_ON);
  {$ENDIF}
end;

function getLangue:string;
begin
  var OSLang := '';
  var LocaleService : IFMXLocaleService;
  if TPlatformServices.Current.SupportsPlatformService(IFMXLocaleService, IInterface(LocaleService)) then
  begin
    OSLang := LocaleService.GetCurrentLangID();
  end;
  result := OSLang;
end;

// Permet de convertir les coordonnées GPS en degré au format Degrés, Minutes, Secondes
function DegDecToDMS( DegDec : Real ):String;
var
  Tmp : real;
  function DeuxCar( S1 : String): String;
  begin
     if length(S1)=1 then Result := '0'+S1 else Result := S1;
  end;
begin
    var S := '';
    S := abs(trunc(DegDec)).ToString;  // récupération la partie entiére
    Tmp := Frac(DegDec);   // renvoi la partie décimale
    Tmp := Tmp * 60;
    S := S + '°' + DeuxCar(abs(trunc(Tmp)).ToString);
    Tmp := Frac(Tmp)*60;
    S := S + chr(39) + DeuxCar(abs(trunc(Tmp)).ToString);
    Tmp := Frac(Tmp)*1000;
    S := S + '"' + abs(trunc(Tmp)).ToString;
    Result := S;
end;

function isInRange(value, min, max : integer): boolean;
begin
  result := (value >= min) and (value <= max);
end;

end.
