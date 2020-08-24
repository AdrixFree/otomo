///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

uses
    Packets, Helpers, Players, Settings, Classes, SysUtils, Backlight,
    Buffs, Attack, Assist, Global, Target, Reskill, UI;

const
    CFG_FILE_NAME = 'settings.ini';
    RADAR_MODE_SOUND = 'sound/radar.wav';
    ASSISTER_MODE_SOUND = 'sound/assist.wav';

var
    Sets: TSettings;
    RadarSound, AssistSound: boolean;
    IsAutoAttack: boolean;
    IsMoveToAssister: boolean;
    AAKey, FRKey, CKey, MAKey: Char;
    NTKey, RRKey, NCSKey, NCKey, WIKey: Char;

///////////////////////////////////////////////////////////
//
//                    WINAPI FUNCTIONS
//
///////////////////////////////////////////////////////////

function GetKeyState(VirtKey: Integer): Integer; stdcall; external 'user32.dll';

///////////////////////////////////////////////////////////
//
//                     HELPER FUNCTIONS
//
///////////////////////////////////////////////////////////

function LoadKey(key: string): Char;
begin
    if (key = 'SPACE')
    then result := ' '
    else result := key[1];
end;

///////////////////////////////////////////////////////////
//
//                   PUBLIC FUNCTIONS
//
///////////////////////////////////////////////////////////

procedure LoadConfigs(fileName: string);
var
    str: string;
    i: integer;
begin
    CheckCancel := Sets.LoadB('Global', 'CheckCancel');
    ArcaneChaos := Sets.LoadB('Global', 'ArcaneChaos');
    str := Sets.LoadS('Global', 'AttackType');
    if (str = 'Light')
    then AtkType := LIGHT_ATTACK
    else
    if (str = 'Solar')
    then AtkType := SOLAR_ATTACK
    else
    if (str = 'Surrender')
    then AtkType := SURRENDER_ATTACK;
    FindFoe := Sets.LoadB('Global', 'FindFOE');

    FindAfterKill := Sets.LoadB('Radar', 'NextTargetAfterKill');
    IsAutoAttack := Sets.LoadB('Global', 'AutoAttack');
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
    for i := 1 to 3 do
    begin
        str := Sets.LoadS('Reskill', 'Range' + IntToStr(i));
        if (str <> '') then RangeList.Add(str);
    end;

    DeadSound := Sets.LoadB('Sound', 'TargetDead');
    RadarSound := Sets.LoadB('Sound', 'RadarMode');
    AssistSound := Sets.LoadB('Sound', 'AssistMode');

    AAKey := LoadKey(Sets.LoadS('Keyboard', 'AutoAttack'));
    FRKey := LoadKey(Sets.LoadS('Keyboard', 'FastResurrection'));
    CKey := LoadKey(Sets.LoadS('Keyboard', 'Cancel'));
    MAKey := LoadKey(Sets.LoadS('Keyboard', 'MoveToAssister'));
    NTKey := LoadKey(Sets.LoadS('Keyboard', 'NextTarget'));
    RRKey := LoadKey(Sets.LoadS('Keyboard', 'ReskillRange'));
    NCSKey := LoadKey(Sets.LoadS('Keyboard', 'NextClass'));
    NCKey := LoadKey(Sets.LoadS('Keyboard', 'NextClan'));
    WIKey := LoadKey(Sets.LoadS('Keyboard', 'WarlordIgnore'));
end;

procedure Init();
begin
    Sets := TSettings.Create(script.Path + CFG_FILE_NAME);

    BackLightInit();
    BuffsInit();
    AttackInit();
    AssistInit();
    TargetInit();

    PrintBotMsg('===========================');
    PrintBotMsg('Welcome to OTOMO v3.2');
    PrintBotMsg('Free Radar + Assister by LanGhost');
    PrintBotMsg('https://github.com/adrixfree');
    PrintBotMsg('Change your configs in settings.ini');
    PrintBotMsg('===========================');

    if (User.ClassID = MM_CLASS)
    then begin
        UserProfile := MM_PROFILE;
        PrintBotMsg('Selected profile: MM');
    end;

    if (User.ClassID = ARCHER_CLASS)
        or (User.ClassID = GHOST_SENTINEL_CLASS)
        or (User.ClassID = MOONLIGHT_SENTINEL_CLASS)
    then begin
        UserProfile := ARCH_PROFILE;
        PrintBotMsg('Selected profile: ARCHER');
    end;
end;

///////////////////////////////////////////////////////////
//
//                       SCRIPT THREADS
//
///////////////////////////////////////////////////////////

procedure KeysThread();
var
    p1, p2: Pointer;
    i: integer;
    target: TL2Char;
    cancel, chaos, aura: TL2Skill;
begin
    while true do
    begin
        try
            if (GetKeyState(ord(AAKey)) > 1) and (IsAutoAttack)
            then begin
                if (AutoAttack)
                then begin
                    AutoAttack := false;
                    PrintBotMsg('Auto attack: STOP');
                end else
                begin
                    AutoAttack := true;
                    PrintBotMsg('Auto attack: RUN');
                end;
                delay(300);
            end;

            if (GetKeyState(ord(FRKey)) > 1)
            then begin
                if (FastRes)
                then begin
                    FastRes := false;
                    PrintBotMsg('Fast resurrection: DISABLED');
                end else
                begin
                    FastRes := true;
                    PrintBotMsg('Fast resurrection: ENABLED');
                end;
                delay(300);
            end;

            if (GetKeyState(ord(CKey)) > 1)
            then begin
                for i := 1 to ASSIST_SKILL_RETRIES do
                begin
                    delay(100);

                    Engine.GetSkillList.ByID(ARCANE_CHAOS_SKILL, chaos);
                    Engine.GetSkillList.ByID(CANCEL_SKILL, cancel);

                    if (chaos.EndTime = 0)
                    then Engine.DUseSkill(ARCANE_CHAOS_SKILL, false, false)
                    else Engine.DUseSkill(CANCEL_SKILL, false, false);

                    if (cancel.EndTime > 0) or (User.Dead) or (User.Target.Dead)
                    then break;
                end;
            end;

            if (not IsRadar)
            then begin
                if (GetKeyState(ord(MAKey)) > 1)
                then begin
                    if (IsMoveToAssister)
                    then begin
                        IsMoveToAssister := false;
                        PrintBotMsg('Move to assister: DISABLED');
                    end else
                    begin
                        IsMoveToAssister := true;
                        PrintBotMsg('Move to assister: ENABLED');
                    end;
                    delay(300);
                end;
            end;

            if (IsRadar)
            then begin
                if (GetKeyState(ord(NTKey)) > 1)
                then begin
                    for i := 0 to CharList.Count - 1 do
                    begin
                        target := CharList.Items(i);
                        if (target.Name <> LastTargetName) and (not target.Dead)
                            and (target.ClanID <> User.ClanID) and (not target.IsMember)
                        then begin
                            if (ClassList[CurClass] <> 'ALL')
                            then begin
                                if (target.ClassID <> ClassToID(ClassList[CurClass]))
                                then continue;
                            end;

                            if (ClanList[CurClan] <> 'ALL')
                            then begin
                                if (target.Clan <> ClanList[CurClan])
                                then continue;
                            end;

                            LastTargetName := target.Name;
                            Engine.SetTarget(target);
                            break;
                        end;
                    end;
                    delay(300);
                end;

                if (GetKeyState(ord(RRKey)) > 1)
                then begin
                    if (CurRange < RangeList.Count - 1)
                    then CurRange := CurRange + 1
                    else CurRange := 0;

                    PrintBotMsg('Reskill range: ' + RangeList[CurRange]);
                    delay(300);
                end;

                if (GetKeyState(ord(NCSKey)) > 1)
                then begin
                    if (CurClass < ClassList.Count - 1)
                    then CurClass := CurClass + 1
                    else CurClass := 0;

                    PrintBotMsg('Target class: ' + ClassList[CurClass]);
                    delay(300);
                end;

                if (GetKeyState(ord(NCKey)) > 1)
                then begin
                    if (CurClan < ClanList.Count - 1)
                    then CurClan := CurClan + 1
                    else CurClan := 0;

                    PrintBotMsg('Target clan: ' + ClanList[CurClan]);
                    delay(300);
                end;

                if (GetKeyState(ord(WIKey)) > 1)
                then begin
                    if (WarlordIgnore)
                    then begin
                        WarlordIgnore := false;
                        PrintBotMsg('Warlord Ignore: DISABLED');
                    end else
                    begin
                        WarlordIgnore := true;
                        PrintBotMsg('Warlord Ignore: ENABLED');
                    end;
                    delay(300);
                end;
            end;
        except
            print('Fail to read keys.');
        end;
        delay(100);
    end;
end;

procedure StatusThread();
var
    last: boolean;
begin
    last := false;

    while True do
    begin
        if (IsRadar and not last)
        then begin
            if (RadarSound) then PlaySound(script.Path + RADAR_MODE_SOUND);
            last := true;
            PrintBotMsg('Switch to RADAR mode');
        end;

        if (not IsRadar and last)
        then  begin
            if (AssistSound) then PlaySound(script.Path + ASSISTER_MODE_SOUND);
            last := false;
            PrintBotMsg('Switch to ASSISTER mode');
        end;
        delay(500);
    end;
end;

procedure OnPacket(ID1, ID2: cardinal; Data: pointer; DataSize: word);
begin
    if (ID1 = CHAR_INFO_PACKET) or (ID1 = MAGIC_SKILL_USE_PACKET)
    then BackLightPacket(ID1, Data, DataSize);

    if (ID1 = MAGIC_SKILL_USE_PACKET)
    then begin
        AutoFlashPacket(Data, DataSize);
        AssistPacket(Data, DataSize);
    end;
end;

procedure MoveToAssisterThread();
var
    i: integer;
    target: TL2Char;
begin
    while true do
    begin
        if (IsMoveToAssister) and (not IsRadar)
        then begin
            for i := 0 to PartyAssisters.Count - 1 do
            begin
                if (CharList.ByName(PartyAssisters[i], target))
                then begin
                    if (not target.Dead) and (target.Target.Name <> target.Name)
                    then begin
                        Engine.DMoveTo(target.X - 10, target.Y + 10, target.Z);
                        break;
                    end;
                end;
            end;
        end;
        delay(300);
    end;
end;

///////////////////////////////////////////////////////////
//
//                      MAIN FUNCTION
//
///////////////////////////////////////////////////////////

begin
    Init();
    LoadConfigs(Script.Path + CFG_FILE_NAME);

    script.NewThread(@AssistThread);
    script.NewThread(@BuffsThread);
    script.NewThread(@AttackThread);
    script.NewThread(@KeysThread);
    script.NewThread(@ReskillThread);
    script.NewThread(@StatusThread);
    script.NewThread(@TargetSaveThread);
    script.NewThread(@HoldTargetThread);
    script.NewThread(@BackLightTitlesThread);
    script.NewThread(@FindTargetAfterKillThread);
    script.NewThread(@BackLightPartyThread);
    script.NewThread(@RunUIThread);
    script.NewThread(@MoveToAssisterThread);
    script.NewThread(@AutoFlashThread);
    script.NewThread(@AssistAttackThread());
end.