unit principale;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, system.Permissions,
  FMX.Objects, FMX.StdCtrls, FMX.Layouts, FMX.Effects, FMX.Filter.Effects, System.Math.Vectors,
  FMX.Controls.Presentation, FMX.Media, System.Sensors, FMX.Controls3D, FMX.Layers3D,
  System.Sensors.Components, FMX.DialogService, System.Math, system.DateUtils, uUtils
  {$IFDEF Android}
  , Androidapi.JNI.App, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers, Androidapi.JNI.Os
  {$ENDIF}
  ;

type
  TfPrincipale = class(TForm)
    BackgroundRect: TRectangle;
    BackgroundImage: TImage;
    HeaderToolBar: TToolBar;
    HeaderBackgroundRect: TRectangle;
    HeaderLabel: TLabel;
    VertScrollBox: TVertScrollBox;
    layTorche: TLayout;
    PrivacyLabel: TLabel;
    swTorche: TSwitch;
    PrivacyImage: TImage;
    FillRGBEffect2: TFillRGBEffect;
    layActiveVeilleuse: TLayout;
    CloudLabel: TLabel;
    swVeilleuse: TSwitch;
    layActiveGPS: TLayout;
    PremiumLabel: TLabel;
    swGPS: TSwitch;
    PremiumImage: TImage;
    FillRGBEffect7: TFillRGBEffect;
    layActiveMeteo: TLayout;
    PaymentLabel: TLabel;
    PaymentImage: TImage;
    FillRGBEffect8: TFillRGBEffect;
    StyleBook1: TStyleBook;
    Camera: TCameraComponent;
    Image1: TImage;
    FillRGBEffect1: TFillRGBEffect;
    layInfosGPS: TLayout;
    LocationSensor: TLocationSensor;
    layInfosMeteo: TLayout;
    veilleuse: TRectangle;
    lblGPS: TLabel;
    tMeteo: TTimer;
    lblMeteo: TLabel;
    layActiveBoussole: TLayout;
    Label1: TLabel;
    Image2: TImage;
    FillRGBEffect3: TFillRGBEffect;
    layInfosBoussole: TLayout;
    lblBoussole: TLabel;
    OrientationSensor: TOrientationSensor;
    tBoussole: TTimer;
    tDateHeure: TTimer;
    layDate: TLayout;
    lblDateHeure: TLabel;
    Image3: TImage;
    FillRGBEffect4: TFillRGBEffect;
    Layout3D1: TLayout3D;
    layBoussole: TLayout;
    Circle1: TCircle;
    Label2: TLabel;
    recViseur: TRectangle;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Circle2: TCircle;
    Image4: TImage;
    procedure swVeilleuseSwitch(Sender: TObject);
    procedure swTorcheSwitch(Sender: TObject);
    procedure LocationSensorLocationChanged(Sender: TObject; const OldLocation, NewLocation: TLocationCoord2D);
    procedure swGPSSwitch(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tMeteoTimer(Sender: TObject);
    procedure OrientationSensorSensorChoosing(Sender: TObject; const Sensors: TSensorArray; var ChoseSensorIndex: Integer);
    procedure tBoussoleTimer(Sender: TObject);
    procedure tDateHeureTimer(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);

  private
    FGeocoder: TGeocoder;
    lTemperature, lPression, lHumidite, lVitesseVent, lDirectionVent, lheureHiver, lheureete: string;
    {$IF Defined(ANDROID)}
        procedure ActivateCameraPermissionRequestResult(Sender: TObject; const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray);
        procedure DisplayRationale(Sender: TObject; const APermissions: TClassicStringDynArray; const APostRationaleProc: TProc);
    {$ENDIF}
    procedure OnGeocodeReverseEvent(const Address: TCivicAddress);
    procedure SetFlashlightState(Active: Boolean);
    procedure CreateIfExists(ASensorCategory: TSensorCategory);
    procedure updateConditionsMeteo;
    procedure SetFlashlightOn;
    procedure chargerLangue(codeLangue: string);
    { Déclarations privées }
  public
    { Déclarations publiques }
    FSensorTemperature, FSensorPression, FSensorHumidite, WindSpeed, WindDirection : TCustomSensor;
  end;

const
  AllCat : TSensorCategories =
  [TSensorCategory.Location, TSensorCategory.Environmental, TSensorCategory.Motion,
  TSensorCategory.Orientation, TSensorCategory.Mechanical, TSensorCategory.Electrical,
  TSensorCategory.Biometric, TSensorCategory.Light, TSensorCategory.Scanner];
  cForm = '%3.2f';

var
  fPrincipale: TfPrincipale;

implementation

{$R *.fmx}

procedure TfPrincipale.swGPSSwitch(Sender: TObject);
begin
  {$IF Defined(ANDROID)}
  if swGPS.IsChecked then begin
    PermissionsService.RequestPermissions([CoarseLocationPermission, FineLocationPermission],
       procedure(const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray)
       begin
         if (Length(AGrantResults) = 2) and ((AGrantResults[0] = TPermissionStatus.Granted) or (AGrantResults[1] = TPermissionStatus.Granted)) then
           LocationSensor.Active := True
         else
           swGPS.IsChecked := False;
       end,
       procedure (const APermissions: TClassicStringDynArray; const APostRationaleProc: TProc)
       begin
         TDialogService.ShowMessage('The app requires access to the device''s location',
           procedure(const AResult: TModalResult)
           begin
             APostRationaleProc;
           end);
       end
    )
  end else
    LocationSensor.Active := False;
{$ELSE}
  LocationSensor.Active := swGPS.IsChecked;
{$ENDIF}
end;

procedure TfPrincipale.swTorcheSwitch(Sender: TObject);
begin
  if swTorche.IsChecked then begin
    {$IF Defined(ANDROID)}
      PermissionsService.RequestPermissions([CameraPermission], ActivateCameraPermissionRequestResult, DisplayRationale);
    {$ELSE}
      SetFlashlightOn;
    {$ENDIF}
  end else SetFlashlightState(false);
end;

procedure TfPrincipale.swVeilleuseSwitch(Sender: TObject);
begin
  veilleuse.Visible := swVeilleuse.IsChecked;
end;

procedure TfPrincipale.tMeteoTimer(Sender: TObject);
begin
  updateConditionsMeteo;
end;

procedure TfPrincipale.tBoussoleTimer(Sender: TObject);
begin
  if OrientationSensor.Sensor<>nil then begin
    if OrientationSensor.sensor.SensorType = TOrientationSensorType.Compass3D then begin
      var angleDeg : integer := Trunc(RadToDeg(ArcTan2(OrientationSensor.sensor.HeadingY, OrientationSensor.sensor.HeadingX)) -90);
      if angleDeg < 0 then angleDeg := angleDeg + 360;
      layBoussole.RotationAngle := -angleDeg;
      var direction := '';
      if isInRange(angleDeg, 0, 24) then direction := ' N';
      if isInRange(angleDeg, 25, 70) then direction := ' NE';
      if isInRange(angleDeg, 71, 115) then direction := ' E';
      if isInRange(angleDeg, 116, 160) then direction := ' SE';
      if isInRange(angleDeg, 161, 205) then direction := ' S';
      if isInRange(angleDeg, 206, 250) then direction := ' SW';
      if isInRange(angleDeg, 251, 295) then direction := ' W';
      if isInRange(angleDeg, 296, 340) then direction := ' NW';
      if isInRange(angleDeg, 341, 360) then direction := ' N';

      lblBoussole.Text := Format('%d° ' + direction, [angleDeg]) ;
    end else lblBoussole.Text := '';
  end else lblBoussole.Text := '';
end;

procedure TfPrincipale.tDateHeureTimer(Sender: TObject);
begin
  var daylight := lheurehiver;
  if TTimeZone.local.IsDaylightTime(now) then daylight := lheureete;
  lblDateHeure.text := formatdatetime('dd/mm/yyyy', now) + sLinebreak +formatdatetime('hh:nn:ss', now) + ' (UTC: '+ formatdatetime('hh:nn:ss', TTimeZone.Local.ToUniversalTime(Now))+')' + sLinebreak + daylight;
end;

procedure TfPrincipale.LocationSensorLocationChanged(Sender: TObject; const OldLocation, NewLocation: TLocationCoord2D);
begin
  var LDecSeparator := FormatSettings.DecimalSeparator;
  var LSettings := FormatSettings;
  try
    FormatSettings.DecimalSeparator := '.';
    lblGPS.Text := '';
    if NewLocation.Latitude > 0 then
      lblGPS.Text := 'Lat:  '+Format('%2.2f', [NewLocation.Latitude])+' N '+'(DMS: '+DegDecToDMS(NewLocation.Latitude)+')'
    else
      lblGPS.Text := 'Lat:  '+Format('%2.2f', [NewLocation.Latitude])+' S '+'(DMS: '+DegDecToDMS(NewLocation.Latitude)+')';

    if NewLocation.Longitude > 0 then
      lblGPS.Text := lblGPS.text + sLineBreak + 'Long:  '+Format('%2.2f', [NewLocation.Longitude])+' E (DMS: '+DegDecToDMS(NewLocation.Longitude)+')'
    else
      lblGPS.text := lblGPS.text + sLineBreak + 'Long:  '+Format('%2.2f', [abs(NewLocation.Longitude)])+' '+Label5.text+' (DMS: '+DegDecToDMS(NewLocation.Longitude)+')';

    lblGPS.Text := lblGPS.text + sLineBreak+ sLineBreak + 'Altitude:  '+format('%3.2f',[LocationSensor.Sensor.Altitude])+' m';

    try
      if not Assigned(FGeocoder) then
      begin
        if Assigned(TGeocoder.Current) then
          FGeocoder := TGeocoder.Current.Create;
        if Assigned(FGeocoder) then
          FGeocoder.OnGeocodeReverse := OnGeocodeReverseEvent;
      end;
    except
    end;

    if Assigned(FGeocoder) and not FGeocoder.Geocoding then
      FGeocoder.GeocodeReverse(NewLocation);

  finally
    FormatSettings.DecimalSeparator := LDecSeparator;
  end;
end;

procedure TfPrincipale.FormCreate(Sender: TObject);
begin
  desactiverVeille;
  chargerLangue(getLangue);

  FSensorTemperature := nil;
  FSensorPression := nil;
  FSensorHumidite := nil;

  TSensorManager.Current.Activate();
  for var LSensorCat in AllCat do
    CreateIfExists(LSensorCat);
end;

procedure TfPrincipale.chargerLangue(codeLangue: string);
begin
  if codeLangue = 'fr' then begin
    HeaderLabel.text := 'Assistant de l''astronome';
    PrivacyLabel.text := 'Allumer la torche';
    CloudLabel.text := 'Veilleuse rouge';
    PaymentLabel.text := 'Météo';
    Label1.text := 'Boussole';
    PremiumLabel.text := 'GPS';
    Label5.text := 'O';
    lTemperature := 'Température';
    lPression := 'Pression';
    lHumidite := 'Humidité';
    lVitesseVent := 'Vitesse du vent';
    lDirectionVent := 'Direction du vent';
    lheureHiver := 'Heure d''hiver';
    lheureEte := 'Heure d''été';
  end else begin
    HeaderLabel.text := 'Astronomer''s assistant';
    PrivacyLabel.text := 'Light the torch';
    CloudLabel.text := 'Red night light';
    PaymentLabel.text := 'Weather';
    Label1.text := 'Compass';
    PremiumLabel.text := 'GPS';
    Label5.text := 'W';
    lTemperature := 'Temperature';
    lPression := 'Pressure';
    lHumidite := 'Humidity';
    lVitesseVent := 'Wind speed';
    lDirectionVent := 'Wind direction';
    lheureHiver := 'DayLight on';
    lheureEte := 'Daylight off';
  end;
end;

procedure TfPrincipale.FormDestroy(Sender: TObject);
begin
  if (FSensorTemperature <> nil) then FSensorTemperature.Stop;
  if (FSensorPression <> nil) then FSensorPression.Stop;
  if (FSensorHumidite <> nil) then FSensorHumidite.Stop;
end;

procedure TfPrincipale.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  recViseur.position.x := lblBoussole.width * 0.5;
  recViseur.position.y := 0;
end;

procedure TfPrincipale.CreateIfExists(ASensorCategory: TSensorCategory);
begin
  var LSensorArray := TSensorManager.Current.GetSensorsByCategory(ASensorCategory);
  for var LSensor in LSensorArray do begin
    if LSensor.Category = TSensorCategory.Environmental then begin
      var ls := TCustomEnvironmentalSensor(LSensor);
      for var LProp in ls.AvailableProperties do begin
        case LProp of
          TCustomEnvironmentalSensor.TProperty.Temperature:
            begin
              FSensorTemperature := LSensor;
              FSensorTemperature.Start;
            end;
          TCustomEnvironmentalSensor.TProperty.Pressure:
            begin
              FSensorPression := LSensor;
              FSensorPression.start;
            end;
          TCustomEnvironmentalSensor.TProperty.Humidity:
            begin
              FSensorHumidite := LSensor;
              FSensorHumidite.start;
            end;
        end;
      end;
    end;
  end;
end;

procedure TfPrincipale.SetFlashlightState(Active : Boolean);
begin
  if Active then Camera.TorchMode := TTorchMode.ModeOn
  else Camera.TorchMode := TTorchMode.ModeOff;
end;

procedure TfPrincipale.updateConditionsMeteo;
begin
  var ls := TCustomEnvironmentalSensor(fSensorTemperature);
  lblMeteo.text := '';
  if Assigned(ls) then lblMeteo.text := 'Température: ' + Format(cForm,[ls.Temperature])+' °C'
  else lblMeteo.text := 'Température: --- C°';

  ls := TCustomEnvironmentalSensor(fSensorPression);
  if Assigned(ls) then lblMeteo.text := lblMeteo.text + sLineBreak + 'Pression: ' + Format(cForm,[ls.Pressure])+' hPa'
  else lblMeteo.text := lblMeteo.text + sLineBreak + 'Pression: --- hPa';

  ls := TCustomEnvironmentalSensor(fSensorHumidite);
  if Assigned(ls) then lblMeteo.text := lblMeteo.text + sLineBreak + 'Humidité: ' +Format(cForm,[ls.Humidity])+'%'
  else lblMeteo.text := lblMeteo.text + sLineBreak + 'Humidité: ---%';

  ls := TCustomEnvironmentalSensor(WindSpeed);
  if Assigned(ls) then lblMeteo.text := lblMeteo.text + sLineBreak + 'Vitesse vent : ' +Format(cForm,[ls.WindSpeed])
  else lblMeteo.text := lblMeteo.text + sLineBreak + 'Vitesse vent : ---';
  ls := TCustomEnvironmentalSensor(WindDirection);
  if Assigned(ls) then lblMeteo.text := lblMeteo.text + sLineBreak + 'Direction vent : ' +Format(cForm,[ls.WindDirection])
  else lblMeteo.text := lblMeteo.text + sLineBreak + 'Direction vent : ---';
end;

procedure TfPrincipale.OnGeocodeReverseEvent(const Address: TCivicAddress);
begin
  lblGPS.text := lblGPS.text + sLineBreak + sLineBreak + Address.AdminArea + sLineBreak+ address.Thoroughfare + ' ' + Address.Locality;
end;

procedure TfPrincipale.OrientationSensorSensorChoosing(Sender: TObject; const Sensors: TSensorArray; var ChoseSensorIndex: Integer);
begin
  var Found := -1;
  for var I := 0 to High(Sensors) do begin
    if (TCustomOrientationSensor.TProperty.HeadingX in TCustomOrientationSensor(Sensors[I]).AvailableProperties) then begin
      Found := i;
      Break;
    end;
  end;

  if Found < 0 then TDialogService.ShowMessage('Compass not available')
  else ChoseSensorIndex := Found;
end;

{$IF Defined(ANDROID)}
procedure TfPrincipale.ActivateCameraPermissionRequestResult(Sender: TObject; const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray);
begin
  if (Length(AGrantResults) = 1) and (AGrantResults[0] = TPermissionStatus.Granted) then
    SetFlashlightOn
  else
    TDialogService.ShowMessage('Cannot access the camera flashlight because the required permission has not been granted');
end;

procedure TfPrincipale.DisplayRationale(Sender: TObject; const APermissions: TClassicStringDynArray; const APostRationaleProc: TProc);
begin
  TDialogService.ShowMessage('The app needs to access the camera in order to work',
    procedure(const AResult: TModalResult)
    begin
      APostRationaleProc;
    end)
end;
{$ENDIF}

procedure TfPrincipale.SetFlashlightOn;
begin
  if Camera.HasFlash then begin
    Camera.Active := True;
    SetFlashlightState(True);
  end else TDialogService.ShowMessage('Cannot turn the camera flashlight on');
end;

end.
