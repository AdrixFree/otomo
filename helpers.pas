///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit Helpers;


interface


uses
    Classes, Packets;

type
    UserClass = (MAG_CLASS, WARIOR_CLASS);


const
    // User skills
    HYDRO_BLAST_SKILL = 1235;
    SOLAR_FLARE_SKILL = 1265;
    LIGHT_VORTEX_SKILL = 1342;
    AURA_FLASH_SKILL = 1417;
    AURA_FLARE_SKILL = 1231;
    AURA_BOLT_SKILL = 1275;
    NOBLESS_SKILL = 1323;
    RESURECTION_SKILL = 1016;
    MASS_RESURECTION_SKILL = 1254;
    FOE_SKILL = 1427;
    CELESTIAL_SHIELD = 1418;
    ALI_CLEANSE = 1425;
    SURRENDER_WATER_SKILL = 1071;
    CANCEL_SKILL = 1056;
    AURA_SYMPHONY_SKILL = 1288;
    ARCANE_CHAOS_SKILL = 1338;
    ICE_DAGGER_SKILL = 1237;
    ICE_VORTEX_SKILL = 1340;
    SPELL_FORCE_SKILL = 427;

    // Target classes
    MM_CLASS = 103;
    BP_CLASS = 97;
    PP_CLASS = 98;
    SORC_CLASS = 94;
    NECR_CLASS = 95;
    SS_CLASS = 110;
    DOMINATOR_CLASS = 115;
    WARLORD_CLASS = 89;
    ARCHER_CLASS = 92;
    GHOST_SENTINEL_CLASS = 109;
    MOONLIGHT_SENTINEL_CLASS = 102;
    ALL_CLASS = 0;

    MSG_PACKET = $4A;
    CHAR_INFO_PACKET = $03;
    MAGIC_SKILL_USE_PACKET = $48;

    CRYSTAL_ITEM = 7917;
    HASTE_POTION_ITEM = 1374;
    SWIFT_ATTACK_POTION_ITEM = 1375;
    MAGIC_HASTE_POTION_ITEM = 6036;
    ELEXIR_CP_ITEM = 8639;
    ELEXIR_HP_ITEM = 8627;
    WALkiNG_SCROLL_ITEM = 6037;

    RAPID_SHOT_BUFF = 99;
    CRYSTAL_BUFF = 2259;
    STANCE_BUFF = 312;
    ACCURACY_BUFF = 256;
    DASH_BUFF = 4;
    NOBLESS_BUFF = 1323;
    BLESSING_SAGITARIUS_BUFF = 416;
    RESIST_AQUA_BUFF = 1182;
    ARCANE_BUFF = 337;
    HASTE_BUFF = 1086;
    WIND_WALK_BUFF = 1204;
    PAAGRIO_HASTE_BUFF = 1282;
    HASTE_POTION_BUFF = 2034;
    SWIFT_ATTACK_POTION_BUFF = 2035;
    MAGIC_HASTE_POTION_BUFF = 2169;
    WISDOM_PAAGRIO_BUFF = 1004;
    ACUMEN_BUFF = 1085;

    SERVER_MSG_CHAT = 18;

    function ClassToStr(clas: integer): string;
    procedure SplitStr(Delimiter: Char; Str: string; ListOfStrings: TStrings);
    procedure PrintBotMsg(text: string);
    function ClassToID(str: string): cardinal;
    procedure SendTitle(oid: Cardinal; str: string);
    function KeyToCode(key: string): integer;
    function GetUserClass(cl: integer): UserClass;

implementation

///////////////////////////////////////////////////////////
//
//                   PUBLIC FUNCTIONS
//
///////////////////////////////////////////////////////////

function ClassToStr(clas: integer): string;
begin
    if (clas = ALL_CLASS)
    then result := 'ALL';

    if (clas = MM_CLASS)
    then result := 'MM';

    if (clas = BP_CLASS)
    then result := 'BP';
end;

procedure SplitStr(Delimiter: Char; Str: string; ListOfStrings: TStrings);
begin
   ListOfStrings.Clear;
   ListOfStrings.Delimiter := Delimiter;
   ListOfStrings.StrictDelimiter := True;
   ListOfStrings.DelimitedText := Str;
end;

procedure PrintBotMsg(text: string);
var
    packet: TNetworkPacket;
begin
    packet := TNetworkPacket.Create();

    packet.WriteC(MSG_PACKET);
    packet.WriteC(255);
    packet.WriteC(255);
    packet.WriteC(255);
    packet.WriteC(255);
    packet.WriteC(SERVER_MSG_CHAT);
    packet.WriteC(0);
    packet.WriteC(0);
    packet.WriteC(0);
    packet.WriteS('-');
    packet.WriteS('OTOMO> ' + text);
    print('OTOMO> ' + text);
    Engine.SendToClient(packet.ToHex);

    packet.Free();
end;

function ClassToID(str: string): cardinal;
begin
    if (str = 'BP') then result := BP_CLASS else
    if (str = 'MM') then result := MM_CLASS;
end;

procedure SendTitle(oid: Cardinal; str: string);
var
    p : TNetworkPacket;
begin
    p := TNetworkPacket.Create();
    p.WriteC($CC);
    p.WriteD(oid);
    p.WriteS(str);
    p.SendToClient();
    p.Free();
end;

function KeyToCode(key: string): integer;
begin
    if (key = '') then result := 0 else
    if (key = 'NUM0') then result := $60 else
    if (key = 'NUM1') then result := $61 else
    if (key = 'NUM2') then result := $62 else
    if (key = 'NUM3') then result := $63 else
    if (key = 'NUM4') then result := $64 else
    if (key = 'NUM5') then result := $65 else
    if (key = 'NUM6') then result := $66 else
    if (key = 'NUM7') then result := $67 else
    if (key = 'NUM8') then result := $68 else
    if (key = 'NUM9') then result := $69 else
    if (key = 'TAB') then result := $09 else
    if (key = 'SHIFT') then result := $10 else
    if (key = 'CAPS') then result := $14 else
    if (key = 'CTRL') then result := $11 else
    if (key = 'ALT') then result := $12 else
    if (key = 'F1') then result := $70 else
    if (key = 'F2') then result := $71 else
    if (key = 'F3') then result := $72 else
    if (key = 'F4') then result := $73 else
    if (key = 'F5') then result := $74 else
    if (key = 'F6') then result := $75 else
    if (key = 'F7') then result := $76 else
    if (key = 'F8') then result := $77 else
    if (key = 'F9') then result := $78 else
    if (key = 'F10') then result := $79 else
    if (key = 'F11') then result := $7A else
    if (key = 'F12') then result := $7B else
    if (key = 'DEL') then result := $2E else
    if (key = 'END') then result := $23 else
    if (key = 'PGDOWN') then result := $22 else
    if (key = 'PGUP') then result := $21 else
    if (key = 'HOME') then result := $24 else
    if (key = 'INS') then result := $2D else
    if (key = 'PAUSE') then result := $13 else
    if (key = 'SPACE') then result := $20 else
    if (key = 'NUM+') then result := $6B else
    if (key = 'NUM-') then result := $6D else
    if (key = 'NUM*') then result := $6A else
    if (key = 'NUM/') then result := $6F else
    if (key = 'NUM.') then result := $6E else
    result := ord(key[1]);
end;

function GetUserClass(cl: integer): UserClass;
begin
    if (cl = MM_CLASS) or (cl = BP_CLASS)
        or (cl = NECR_CLASS) or (cl = PP_CLASS) or (cl = SS_CLASS)
        or (cl = SORC_CLASS) or (cl = DOMINATOR_CLASS)
    then result := MAG_CLASS
    else result := WARIOR_CLASS;
end;

end.