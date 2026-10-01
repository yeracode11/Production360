; Production360 — Inno Setup installer (includes Visual C++ 2015–2022 x64)
;
; Build on Windows:
;   cd mobile\windows\installer
;   .\build-installer.ps1
;
; Output:
;   mobile\build\windows\installer\Production360-Setup-{version}.exe

#ifndef MyAppVersion
  #define MyAppVersion "1.0.5"
#endif

#define MyAppName "Production360"
#define MyAppPublisher "Production360"
#define MyAppExeName "Production360.exe"
#define MyAppBuildDir "..\..\build\windows\x64\runner\Release"
#define MyAppOutputDir "..\..\build\windows\installer"
#define VcRedistSource "redist\vc_redist.x64.exe"

[Setup]
AppId={{E4A91C2D-8B3F-4A6E-9C1D-EF1234567890}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir={#MyAppOutputDir}
OutputBaseFilename={#MyAppName}-Setup-{#MyAppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MyAppBuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#VcRedistSource}"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function VcRedistExitOk(ResultCode: Integer): Boolean;
begin
  { 0 = OK, 1638 = newer runtime already installed, 3010 = OK, reboot suggested }
  Result := (ResultCode = 0) or (ResultCode = 1638) or (ResultCode = 3010);
end;

procedure InstallVCRedist;
var
  ResultCode: Integer;
  VcPath: String;
begin
  VcPath := ExpandConstant('{tmp}\vc_redist.x64.exe');
  if not FileExists(VcPath) then
  begin
    MsgBox(
      'В установщик не включён vc_redist.x64.exe.' + #13#10 +
      'Соберите инсталлер командой: build-installer.ps1',
      mbError, MB_OK);
    Abort;
  end;

  WizardForm.StatusLabel.Caption := 'Установка Visual C++ Runtime (x64)...';
  try
    WizardForm.ProgressBar.Style := npbstMarquee;
  except
  end;

  if not Exec(VcPath, '/install /quiet /norestart', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    MsgBox('Не удалось запустить установку Visual C++ Runtime.', mbError, MB_OK);
    Abort;
  end;

  if not VcRedistExitOk(ResultCode) then
  begin
    MsgBox(
      'Visual C++ Runtime не установлен (код ' + IntToStr(ResultCode) + ').' + #13#10 +
      'Без него приложение не запустится (ошибки VCRUNTIME140 / MSVCP140).',
      mbError, MB_OK);
    Abort;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    InstallVCRedist;
end;

