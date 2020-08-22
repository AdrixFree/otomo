///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit Backlight;

interface

uses
    Classes, Helpers, Players, Packets;

const
    MAX_ASSISTERS = 50;

    procedure BackLightInit();
    procedure BackLightPartyThread();
    procedure BackLightTitlesThread();
    procedure BackLightPacket(ID1: cardinal; Data: pointer; DataSize: word);

var
    ShowLeader: boolean;
    ShowAssisters: boolean;
    ShowPartyMembers: boolean;
    PartyList: TStringList;
    Leaders: TStringList;
    Assisters: TList;

implementation

///////////////////////////////////////////////////////////
//
//                      PUBLIC FUNCTIONS
//
///////////////////////////////////////////////////////////

procedure BackLightInit();
begin
    Assisters := TList.Create();
    Leaders := TStringList.Create();
    PartyList := TStringList.Create();
end;

procedure BackLightPacket(ID1: cardinal; Data: pointer; DataSize: word);
var
    player: TPlayer;
    i: integer;
    skill, oid: cardinal;
    found: boolean;
    packet: TNetworkPacket;
begin
    try
        if (ID1 = MAGIC_SKILL_USE_PACKET)
        then begin
            packet := TNetworkPacket.Create(Data, DataSize);

            oid := packet.ReadD();
            packet.ReadD();
            skill := packet.ReadD();

            if (skill = SURRENDER_WATER_SKILL)
            then begin
                found := false;
                for i := 0 to Assisters.Count - 1 do
                begin
                    if (oid = Cardinal(Assisters[i]))
                    then begin
                        found := true;
                        break;
                    end;
                end;

                if (not found)
                then begin
                    if (Assisters.Count > MAX_ASSISTERS)
                    then Assisters.Delete(MAX_ASSISTERS);
                    Assisters.Insert(0, Pointer(oid));
                end;
            end;

            packet.Free();
        end;

        if (ID1 = CHAR_INFO_PACKET)
        then begin
            player := TPlayer.Create(Data, DataSize);
            if (player.Team = 0)
            then begin
                for i := 0 to Assisters.Count - 1 do
                begin
                    if (Cardinal(Assisters[i]) = player.OID)
                    then begin
                        player.SetTeam(2);
                        player.SetTitleColor($FF, 0, 0);
                        player.SetNickColor($FF, $FF, 0);
                        break;
                    end;
                end;

                for i := 0 to PartyList.Count - 1 do
                begin
                    if (PartyList[i] = player.Name)
                    then begin
                        player.SetTeam(1);
                        player.SetTitleColor(0, $BF, $FF);
                        player.SetNickColor(0, $BF, $FF);
                        break;
                    end;
                end;

                if (Leaders[0] = player.Name)
                then begin
                    player.SetTeam(1);
                    player.SetNickColor(0, $FF, 0);
                    player.SetTitleColor(0, $FF, 0);
                    player.SetHero(true);
                end;

                if (player.Team > 0)
                then player.SendToClient();
            end;
            player.Free();
        end;
    except
        print('Fail to process server packet');
    end;
end;

///////////////////////////////////////////////////////////
//
//                      MODULE THREADS
//
///////////////////////////////////////////////////////////

procedure BackLightPartyThread();
var
    i: integer;
begin
    while true do
    begin
        try
            if (ShowPartyMembers)
            then begin
                PartyList.Clear();
                for i := 0 to Party.Chars.Count - 1 do
                begin
                    PartyList.Add(Party.Chars.Items(i).Name);
                end;
            end;
        except
            print('Fail to process party');
        end;
        delay(1000);
    end;
end;

procedure BackLightTitlesThread();
var
    i, j: integer;
    target: TL2Char;
    found: boolean;
begin
    while true do
    begin
        try
            for i := 0 to CharList.Count - 1 do
            begin
                target := CharList.Items(i);

                if (ShowAssisters) and (target.ClanID <> User.ClanID)
                then begin
                    for j := 0 to Assisters.Count - 1 do
                    begin
                        if (target.OID = Cardinal(Assisters[j]))
                        then begin
                            if (target.ClanID = User.ClanID)
                            then Assisters.Delete(j)
                            else
                            begin
                                SendTitle(target.OID, '>>> ASSISTER <<<');
                                delay(10);
                            end;
                            break;
                        end;
                    end;
                end;

                if (target.Name = Leaders[0]) and (ShowLeader)
                then begin
                    SendTitle(target.OID, '>>> LEADER <<<');
                    delay(10);
                end;
            end;
        except
            print('Fail to set title');
        end;
        delay(1000);
    end;
end;

end.