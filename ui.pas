///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit UI;

interface

uses
    SysUtils, Classes, Dialogs;

const
    UI_MOD = 0;

    procedure RunUIThread;

implementation

///////////////////////////////////////////////////////////
//
//                      MODULE THREADS
//
///////////////////////////////////////////////////////////

procedure RunUIThread;
var
    path: string;
begin
    path:= script.Path + 'ui.dll';

    if (FileExists(path))
    then begin
        if (not Script.StartPlugin(path, nil, false)) then
        begin
            ShowMessage('Fail to start UI plugin!');
            Script.Stop;
        end;
    end else
    begin
        ShowMessage('Error!' + #13#10 + 'Download ' + 'ui.dll');
        script.Stop;
    end;
end;

end.