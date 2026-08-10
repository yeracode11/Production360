; Production360 — Inno Setup installer
;
; Prerequisites:
;   1. flutter build windows --release
;   2. vc_redist.x64.exe in redist\ (download via build-installer.ps1)
;   3. Inno Setup 6: https://jrsoftware.org/isdl.php
;
; Compile:
;   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" Production360.iss
;   or run: .\build-installer.ps1

#ifndef MyAppVersion
  #define MyAppVersion "1.0.4"
#endif

#define MyAppName "Production360"
#define MyAppPublisher "Production360"
#define MyAppExeName "Production360.exe"
#define MyAppBuildDir "..\..\build\windows\x64\runner\Release"
#define MyAppOutputDir "..\..\build\windows\installer"

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
Name: "desktopicon"; Description: "Создать ярлык на рабочем столе"; GroupDescription: "Дополнительно:"; Flags: unchecked

[Files]
Source: "{#MyAppBuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "redist\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Установка Visual C++ Runtime..."; Flags: waituntilterminated
Filename: "{app}\{#MyAppExeName}"; Description: "Запустить {#MyAppName}"; Flags: nowait postinstall skipifsilent
