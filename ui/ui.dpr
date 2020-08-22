library ui;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Forms,
  Dialogs,
  MainForm in 'MainForm.pas' {Form1};

{$R *.res}

var
  AppLoad: Boolean;

function ThreadMain(P: Pointer): Integer;
begin
  try
    MainThreadID:= GetCurrentThreadId;
    Application.Title := '';
    Application := TApplication.Create(nil);
    Application.Initialize;
    Application.ShowMainForm:= true;
    Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
    Application.Free;
  except
  end;
  AppLoad:= false;
  Endthread(0);
  Result:= 0;
end;

function StartPlugin(AppHandle: Cardinal; PProc: Pointer): Cardinal; stdcall;
var
  ID: cardinal;
begin
  if not AppLoad then
  begin
    AppLoad:= true;
    Application.Free;
    CloseHandle(BeginThread(nil, 0, @ThreadMain, nil, 0, ID));
  end;
  Result:= 1;
end;

procedure ShowPlugin; stdcall;
begin
  if (AppLoad) then
  begin
    PostMessage(Form1.Handle, WM_PluginShow, 0, 0);
  end;
end;

function StopPlugin: Boolean; stdcall;
begin
  if (not AppLoad)
  then Exit;
  
  while (AppLoad) do
  begin
    PostMessage(Application.MainForm.Handle, WM_QUIT, 0, 0);
    PostMessage(Application.MainForm.Handle, WM_QUIT, 0, 0);
    PostMessage(Application.MainForm.Handle, WM_QUIT, 0, 0);
    PostMessage(Application.MainForm.Handle, WM_QUIT, 0, 0);
    PostMessage(Application.MainForm.Handle, WM_QUIT, 0, 0);
    Sleep(500);
  end;
  Application:= TApplication.Create(nil);
  Result:= true;
end;

exports
  StartPlugin,
  StopPlugin,
  ShowPlugin;

end.
