///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit Packets;

interface

type
    TNetworkPacket = class
    public
        procedure WriteQ(value: Int64);
        procedure WriteD(value: Cardinal);
        procedure WriteH(value: Word);
        procedure WriteC(value: Byte);
        procedure WriteS(value: String);
        function ReadQ(): Int64;
        function ReadD(): Cardinal;
        function ReadH(): Word;
        function ReadC(): Byte;
        function ReadS(): String;
        function ToHex(): String;
        function SendToServer(): Boolean;
        function SendToClient(): Boolean;
        constructor Create(pData: PChar; size: Word); overload;
        constructor Create(); overload;
    private
        data: Array[0..10240] of Byte;
        Current: Integer;
    end;


implementation


uses
    SysUtils;


constructor TNetworkPacket.Create(pData: PChar; size: Word);
begin
    inherited Create;
    Move(pData^, PChar(@data[0])^, size);
    Current := 0;
end;

constructor TNetworkPacket.Create();
begin
    inherited Create;
    Current := 0;
end;

function TNetworkPacket.ReadQ;
begin
    Result:= PInt64(@data[Current])^;
    Current:= Current + SizeOf(Int64);
end;

function TNetworkPacket.ReadD;
begin
    Result:= PCardinal(@data[Current])^;
    Current:= Current + SizeOf(Cardinal);
end;

function TNetworkPacket.ReadH;
begin
    Result:= PWord(@data[Current])^;
    Current:= Current + SizeOf(Word);
end;

function TNetworkPacket.ReadC;
begin
    Result:= PByte(@data[Current])^;
    Current:= Current + SizeOf(Byte);
end;

function TNetworkPacket.ReadS;
begin
    Result:= String(PChar(@data[Current]));
    Current:= Current + (Length(Result) + 1) * SizeOf(Char);
end;

procedure TNetworkPacket.WriteQ;
begin
    (PInt64(@data[Current])^):= value;
    Current:= Current + SizeOf(Int64);
end;

procedure TNetworkPacket.WriteD;
begin
    (PCardinal(@data[Current])^):= value;
    Current:= Current + SizeOf(Cardinal);
end;

procedure TNetworkPacket.WriteH;
begin
    (PWord(@data[Current])^):= value;
    Current:= Current + SizeOf(Word);
end;

procedure TNetworkPacket.WriteC;
begin
    (PByte(@data[Current])^):= value;
    Current:= Current + SizeOf(Byte);
end;

procedure TNetworkPacket.WriteS;
begin
    Move(value^, PChar(@data[Current])^, (Length(value) + 1) * SizeOf(Char));
    Current:= Current + (Length(value) + 1) * SizeOf(Char);
end;

function TNetworkPacket.ToHex;
var
    i: Cardinal;
begin
    Result := '';
    for i := 0 to Current - 1 do 
        Result := Result + IntToHex(data[i], 2);
end;

function TNetworkPacket.SendToServer;
begin
    Engine.SendToServer(Self.ToHex);
end;

function TNetworkPacket.SendToClient;
begin
    Engine.SendToClient(Self.ToHex);
end;


end.