///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit Settings;


interface


uses
    SysUtils;


type
    TSettings = packed record
    public
        constructor Create(const name: string);
        procedure SaveS(const Section, Key, Data: string); overload;
        procedure SaveI(const Section, Key: string; Data: Integer); overload;
        procedure SaveB(const Section, Key: string; Data: boolean);
        function  LoadS(const Section, Key: string; DefData: string  = ''): string; overload;
        function  LoadI(const Section, Key: string; DefData: integer = 0) : integer; overload;
        function  LoadB(const Section, Key: string; DefData: boolean = false): boolean; overload;
    private
        CfgFile: string;
        Buf: array [0..2048] of Byte;
        function BoolToStr(const value : boolean): string;
    end;

implementation

///////////////////////////////////////////////////////////
//
//                   WINAPI FUNCTIONS
//
///////////////////////////////////////////////////////////

function GetPrivateProfileIntW(lpAppName, lpKeyName: PChar; nDefault: Integer; lpFileName: PChar): Integer; stdcall; external 'Kernel32.dll';
function GetPrivateProfileStringW(lpAppName, lpKeyName, lpDefault: PWideChar; lpReturnedString: Pointer; nSize: DWORD; lpFileName: PWideChar): DWORD; stdcall; external 'Kernel32.dll';
function WritePrivateProfileStringW(lpAppName, lpKeyName, lpString, lpFileName: PChar): Boolean; stdcall; external 'Kernel32.dll';

///////////////////////////////////////////////////////////
//
//                   PUBLIC FUNCTIONS
//
///////////////////////////////////////////////////////////
 
constructor TSettings.Create(const Name: string);
begin
    CfgFile := Name;
end;

procedure TSettings.SaveS(const Section, Key, Data: string);
begin
    WritePrivateProfileStringW(PChar(Section), PChar(Key), PChar(Data), PChar(CfgFile));
end;

procedure TSettings.SaveI(const Section, Key: string; Data: Integer);
begin
    SaveS(Section, Key, IntToStr(Data));
end;

procedure TSettings.SaveB(const Section, Key: string; Data: boolean);
begin
    SaveS(Section, Key, BoolToStr(Data));
end;

function TSettings.LoadS(const Section, Key: string; DefData: string = ''): string;
begin
    GetPrivateProfileStringW(PChar(Section), PChar(Key), PChar(DefData), @Buf, 2048, PChar(CfgFile));
    Result := PChar(@Buf);
end;

function TSettings.LoadI(const Section, Key: string; DefData: integer = 0): Integer;
begin
    Result := GetPrivateProfileIntW(PChar(Section), PChar(Key), DefData, PChar(CfgFile));
end;

function TSettings.LoadB(const Section, Key: string; DefData: boolean = false): boolean;
begin
    GetPrivateProfileStringW(PChar(Section), PChar(Key), PChar(DefData), @Buf, 2048, PChar(CfgFile));
    if (AnsiCompareText(PChar(@Buf), 'true') = 0) then
        Result := true
    else
        Result := false;
end;

///////////////////////////////////////////////////////////
//
//                    PRIVATE FUNCTIONS
//
///////////////////////////////////////////////////////////

function TSettings.BoolToStr;
begin
   if value then
    Result := 'True'
   else
    Result := 'False';
end; 


end.