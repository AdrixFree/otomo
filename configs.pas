///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit Configs;

interface

uses
    Keyboard, Attack, Assist, Target, Reskill, Global, Buffs,
    SysUtils, Backlight, Helpers;

const
    CFG_MOD = 0;
    procedure LoadConfigs(fileName: string);

implementation

///////////////////////////////////////////////////////////
//
//                       PUBLIC FUNCTIONS
//
///////////////////////////////////////////////////////////

procedure LoadConfigs(fileName: string);
var
    str: string;
    i: integer;
begin
    CheckCancel := Sets.LoadB('Global', 'CheckCancel');
    ArcaneChaos := Sets.LoadB('Global', 'ArcaneChaos');
    i := Sets.LoadI('Global', 'RangeAttackType');
    if (i = 1)
    then AtkType := SURRENDER_ATTACK
    else
    if (i = 2)
    then AtkType := LIGHT_ATTACK
    else
    if (i = 3)
    then AtkType := ICE_ATTACK
    else
    if (i = 4)
    then AtkType := SOLAR_ATTACK;

    i := Sets.LoadI('Global', 'MiliAttackType');
    if (i = 1)
    then AtkTypeMili := BOLT_ATTACK
    else
    if (i = 2)
    then AtkTypeMili := FLARE_ATTACK;

    FindFoe := Sets.LoadB('Global', 'FindFOE');

    for i := 1 to 4 do
    begin
        str := Sets.LoadS('Global', 'ExcludedClan' + IntToStr(i));
        if (str <> '') then ExcludedClans.Add(str);
    end;

    FlashAfterRes := Sets.LoadB('Global', 'FlashAfterRes');

    FindAfterKill := Sets.LoadB('Radar', 'NextTargetAfterKill');
    for i := 1 to 4 do
    begin
        str := Sets.LoadS('Radar', 'Clan' + IntToStr(i));
        if (str <> '') then ClanList.Add(str);
    end;

    for i := 1 to 3 do
    begin
        str := Sets.LoadS('Assist', 'Assister' + IntToStr(i));
        if (str <> '') then PartyAssisters.Add(str);
    end;

    Leaders.Add(Sets.LoadS('BackLight', 'LeaderName'));
    ShowLeader := Sets.LoadB('BackLight', 'ShowLeader');
    ShowPartyMembers := Sets.LoadB('BackLight', 'ShowPartyMembers');
    ShowAssisters := Sets.LoadB('BackLight', 'ShowAssisters');

    PartyWalkingScroll := Sets.LoadB('Buff', 'PartyWalkingScroll');
    PartyResistAqua := Sets.LoadB('Buff', 'PartyResistAqua');
    Crystal := Sets.LoadB('Buff', 'SanctityCrystal');
    ResistAquaInCombat := Sets.LoadB('Buff', 'ResistAquaInCombat');
    PartyNobless := Sets.LoadB('Buff', 'PartyNobless');
    AutoDash := Sets.LoadB('Buff', 'AutoDash');

    ReskillDelay := Sets.LoadI('Reskill', 'Delay');
    ReskillSolar := Sets.LoadB('Reskill', 'AutoSolar');
    ReskillDetect := Sets.LoadB('Reskill', 'ReskillSoundChat');

    for i := 1 to 3 do
    begin
        str := Sets.LoadS('Reskill', 'Range' + IntToStr(i));
        if (str <> '') then RangeList.Add(str);
    end;

    DeadSound := Sets.LoadB('Sound', 'TargetDead');
    RadarSound := Sets.LoadB('Sound', 'RadarMode');
    AssistSound := Sets.LoadB('Sound', 'AssistMode');

    SCPKey := KeyToCode(Sets.LoadS('Keyboard', 'ScriptPause'));
    AAPKey := KeyToCode(Sets.LoadS('Keyboard', 'AutoAssistPause'));
    AAKey := KeyToCode(Sets.LoadS('Keyboard', 'AutoAttack'));
    RAKey := KeyToCode(Sets.LoadS('Keyboard', 'NextAutoAttackType'));
    FRKey := KeyToCode(Sets.LoadS('Keyboard', 'FastResurrection'));
    CKey := KeyToCode(Sets.LoadS('Keyboard', 'Cancel'));
    MAKey := KeyToCode(Sets.LoadS('Keyboard', 'MoveToAssister'));
    NTKey := KeyToCode(Sets.LoadS('Keyboard', 'NextTarget'));
    RRKey := KeyToCode(Sets.LoadS('Keyboard', 'ReskillRange'));
    NCSKey := KeyToCode(Sets.LoadS('Keyboard', 'NextClass'));
    NCKey := KeyToCode(Sets.LoadS('Keyboard', 'NextClan'));
    WIKey := KeyToCode(Sets.LoadS('Keyboard', 'WarlordIgnore'));
end;

end.