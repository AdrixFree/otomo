///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit Players;

interface

uses
    SysUtils;

const
    TEAM_NONE = 0;
    TEAM_BLUE = 1;
    TEAM_RED = 2;

    DATA_SIZE = 10240;

    SIGNATURE_DEFAULT_POS = 12;

type
    TPlayer = class
    public
        constructor Create(pData: PChar; sz: Word);
        procedure Update(pData: PChar; sz: Word);
        function OID(): cardinal;
        function Name(): String;
        function Team(): byte;
        procedure SetHero(status: boolean);
        function Hero(): boolean;
        procedure SetTeam(team: byte);
        procedure SetTitleColor(r, g, b: byte);
        procedure SetNickColor(r, g, b: byte);
        function ToHex(): String;
        function SendToClient(): Boolean;
    private
        Data: array[0..DATA_SIZE] of Byte;
        Size: Word;
        function FindSignature(): integer;
    end;

implementation

var
    Delta: integer = 0;
    SigFound: boolean = false;

///////////////////////////////////////////////////////////
//
//                    PUBLIC FUNCTIONS
//
///////////////////////////////////////////////////////////

constructor TPlayer.Create(pData: PChar; sz: Word);
var
    i, p: integer;
begin
    inherited Create;

    Move(pData^, PChar(@Data[0])^, sz);
    Size := sz;

    if (not SigFound)
    then begin
        p := FindSignature();
        if (p <> -1)
        then begin
            Delta := p - SIGNATURE_DEFAULT_POS;
            SigFound := true;
        end;
    end;
end;

procedure TPlayer.Update(pData: PChar; sz: Word);
begin
    Move(pData^, PChar(@Data[0])^, sz);
    Size := sz;
end;

function TPlayer.SendToClient;
begin
    Engine.SendToClient(Self.ToHex);
end;

function TPlayer.OID(): cardinal;
begin
    result := PCardinal(@Data[16])^;
end;

function TPlayer.Name(): String;
begin
    result := String(PChar(@Data[20]));
end;

procedure TPlayer.SetHero(status: boolean);
begin
    if (status)
    then (PByte(@Data[Size - (42 + Delta)])^) := 1
    else (PByte(@Data[Size - (42 + Delta)])^) := 0;
end;

function TPlayer.Hero(): boolean;
var
    field: byte;
begin
    field := PByte(@Data[Size - (42 + Delta)])^;

    if (field = 1)
    then result := true
    else result := false;
end;

procedure TPlayer.SetTeam(team: byte);
begin
    (PByte(@Data[Size - (48 + Delta)])^) := team;
end;

function TPlayer.Team(): byte;
begin
    result := PByte(@Data[Size - (48 + Delta)])^;
end;

procedure TPlayer.SetTitleColor(r, g, b: byte);
begin
    (PByte(@Data[Size - (10 + Delta)])^) := b;
    (PByte(@Data[Size - (11 + Delta)])^) := g;
    (PByte(@Data[Size - (12 + Delta)])^) := r;
end;

procedure TPlayer.SetNickColor(r, g, b: byte);
begin
    (PByte(@Data[Size - (26 + Delta)])^) := b;
    (PByte(@Data[Size - (27 + Delta)])^) := g;
    (PByte(@Data[Size - (28 + Delta)])^) := r;
end;

function TPlayer.ToHex;
var
    i: Cardinal;
begin
    Result := '03 ';
    for i := 0 to Size - 1 do 
        Result := Result + IntToHex(data[i], 2);
end;

///////////////////////////////////////////////////////////
//
//                  PRIVATE FUNCTIONS
//
///////////////////////////////////////////////////////////

function TPlayer.FindSignature(): integer;
var
    i, p: integer;
begin
    p := 0;

    for i := Size - 1 downto 50 do
    begin
        if (PByte(@Data[i])^ = $00) and (PByte(@Data[i+1])^ = $77)
            and (PByte(@Data[i+2])^ = $FF) and (PByte(@Data[i+3])^ = $FF)
        then begin
            result := p;
            exit;
        end;
        p := p + 1;
    end;

    result := -1;
end;

end.