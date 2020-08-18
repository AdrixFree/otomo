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


const
    // User skills
    HYDRO_BLAST_SKILL = 1235;
    SOLAR_FLARE_SKILL = 1265;
    LIGHT_VORTEX_SKILL = 1342;
    AURA_FLASH_SKILL = 1417;
    AURA_FLARE_SKILL = 1231;
    AURA_BOLT_SKILL = 1275;
    NOOBLE_SKILL = 1323;
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
    MAGIS_SKILL_USE_PACKET = $48;

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


end.