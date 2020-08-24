library ui;

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Forms,
  Dialogs,
  MainForm;

{$R *.res}

var
  AppLoad: Boolean;

///////////////////////////////////////////////////////////
//
//                   PRIVATE  FUNCTIONS
//
///////////////////////////////////////////////////////////

function ThreadMain(P: Pointer): Integer;
begin
    try
        MainThreadID:= GetCurrentThreadId;
        Application.Title := 'OTOMO';
        Application := TApplication.Create(nil);
        Application.Initialize;
        Application.ShowMainForm := true;

        Application.CreateForm(TForm1, Form1);

        Application.Run;
        Application.Free;
    except
    end;
    AppLoad:= false;
    EndThread(0);
    Result:= 0;
end;

///////////////////////////////////////////////////////////
//
//                   PUBLIC FUNCTIONS
//
///////////////////////////////////////////////////////////

function StartPlugin(AppHandle: Cardinal; PProc: Pointer): Cardinal; stdcall;
var
    ID: cardinal;
begin
    if (not AppLoad)
    then begin
        AppLoad:= true;
        Application.Free;
        CloseHandle(BeginThread(nil, 0, @ThreadMain, nil, 0, ID));
    end;
    Result:= 1;
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

///////////////////////////////////////////////////////////
//
//                        EXPORTS
//
///////////////////////////////////////////////////////////

exports
    StartPlugin,
    StopPlugin;

end.
