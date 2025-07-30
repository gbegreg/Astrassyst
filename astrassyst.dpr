program astrassyst;

uses
  System.StartUpCopy,
  FMX.Forms,
  principale in 'principale.pas' {fPrincipale},
  uUtils in 'uUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Portrait];
  Application.CreateForm(TfPrincipale, fPrincipale);
  Application.Run;
end.
