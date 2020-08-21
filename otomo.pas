///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

uses
    Packets, Helpers, Players, Settings, Classes, SysUtils;

const
    CFG_FILE_NAME = 'settings.ini';
    CANCEL_END_SOUND = 'cancel.wav';
    RADAR_MODE_SOUND = 'radar.wav';
    ASSISTER_MODE_SOUND = 'assist.wav';
    DEAD_SOUND = 'dead.wav';
    FOE_CAST_SOUND = 'foe.wav';
    ARCH_ATTACK_DELAY = 500;
    ELEXIR_MIN_HP = 15;
    ELEXIR_MIN_CP = 15;
    MAX_ASSISTERS = 50;
    MM_BUFFS_COUNT = 6;
    CANCEL_END_TIME = 2;
    RANGE_SKILLS_COUNT = 4;
    SOLAR_SKILLS_COUNT = 3;
    RESIST_AQUA_DISTANCE = 400;
    NOBLESS_DISTANCE = 400;
    ICE_DAGGER_DISTANCE = 900;
    WALKING_SCROLL_DISTANCE = 400;
    TRANCE_DEBUFF_BIT = 7;
    MIN_CAST_SPD = 1671;
    ASSIST_SKILLS_COUNT = 3;
    FLASH_SKILLS_COUNT = 7;
    FLASH_DISTANCE = 200;
    ASSIST_SKILL_RETRIES = 30;
    ARCH_BUFFS_COUNT = 9;

type
    AttackType = (SURRENDER_ATTACK, LIGHT_ATTACK, SOLAR_ATTACK);

var
    Sets: TSettings;
    FoundCancel: boolean = false;
    LastTargetName: string;
    FastRes: boolean = false;
    Crystal: boolean;
    PartyWalkingScroll: boolean;
    PartyResistAqua: boolean;
    ResistAquaInCombat: boolean;
    CheckCancel: boolean;
    AutoAttack: boolean;
    AtkType: AttackType;
    PartyNobless: boolean;
    AssistStatus: boolean = true;
    MMBuffs: array[1..MM_BUFFS_COUNT] of integer;
    SurrRangeSkills: array[1..RANGE_SKILLS_COUNT] of integer;
    LightRangeSkills: array[1..RANGE_SKILLS_COUNT] of integer;
    SolarRangeSkills: array[1..SOLAR_SKILLS_COUNT] of integer;
    AssistSkills: array[1..ASSIST_SKILLS_COUNT] of integer;
    FlashSkills: array[1..FLASH_SKILLS_COUNT] of integer;
    ArchBuffs : array[1..ARCH_BUFFS_COUNT] of integer;
    PartyAssisters: TStringList;
    CurTarget, PrevTarget: TL2Live;
    IsRadar: boolean = false;
    WarlordIgnore: boolean = false;
    RangeList, ClassList, ClanList: TStringList;
    CurRange, CurClass, CurClan: integer;
    ReskillDelay: integer;
    ReskillSolar: boolean;
    DeadSound, RadarSound, AssistSound: boolean;
    Leaders, Assisters: TStringList;
    FindFoe, ArcaneChaos: boolean;
    ShowLeader, ShowAssisters, FindAfterKill: boolean;
    AutoDash: boolean;
    PartyList: TStringList;
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

function IsFlashSkill(id : cardinal) : boolean;
var
    i: integer;
begin
    for i := 1 to FLASH_SKILLS_COUNT do
    begin
        if (id = FlashSkills[i])
        then begin
            result := true;
            exit;
        end;
    end;
    result := false;
end;

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
    IsAutoAttack := Sets.LoadS('Radar', 'AutoAttack');
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

    Leaders.Add(Sets.LoadS('Titles', 'LeaderName'));
    ShowLeader := Sets.LoadB('Titles', 'ShowLeader');
    ShowAssisters := Sets.LoadB('Titles', 'ShowAssisters');

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
    PartyAssisters := TStringList.Create();
    Sets := TSettings.Create(script.Path + CFG_FILE_NAME);
    RangeList := TStringList.Create();
    ClassList := TStringList.Create();
    ClanList := TStringList.Create();
    Assisters := TStringList.Create();
    Leaders := TStringList.Create();
    PartyList := TStringList.Create();

    CurRange := 0;
    CurClass := 0;
    CurClan := 0;

    ClassList.Add('ALL');
    ClassList.Add('MM');
    ClassList.Add('BP');

    ClanList.Add('ALL');

    MMBuffs[1] := NOBLESS_BUFF;
    MMBuffs[2] := ARCANE_BUFF;
    MMBuffs[3] := CRYSTAL_BUFF;
    MMBuffs[4] := RESIST_AQUA_BUFF;
    MMBuffs[5] := WIND_WALK_BUFF;
    MMBuffs[6] := ACUMEN_BUFF;

    ArchBuffs[1] := RAPID_SHOT_BUFF;
    ArchBuffs[2] := CRYSTAL_BUFF;
    ArchBuffs[3] := STANCE_BUFF;
    ArchBuffs[4] := ACCURACY_BUFF;
    ArchBuffs[5] := DASH_BUFF;
    ArchBuffs[6] := NOBLESS_BUFF;
    ArchBuffs[7] := BLESSING_SAGITARIUS_BUFF;
    ArchBuffs[8] := HASTE_BUFF;
    ArchBuffs[9] := WIND_WALK_BUFF;

    SurrRangeSkills[1] := SURRENDER_WATER_SKILL;
    SurrRangeSkills[2] := SOLAR_FLARE_SKILL;
    SurrRangeSkills[3] := HYDRO_BLAST_SKILL;
    SurrRangeSkills[4] := ICE_DAGGER_SKILL;

    LightRangeSkills[1] := SOLAR_FLARE_SKILL;
    LightRangeSkills[2] := LIGHT_VORTEX_SKILL;
    LightRangeSkills[3] := HYDRO_BLAST_SKILL;
    LightRangeSkills[4] := ICE_DAGGER_SKILL;

    SolarRangeSkills[1] := SOLAR_FLARE_SKILL;
    SolarRangeSkills[2] := HYDRO_BLAST_SKILL;
    SolarRangeSkills[3] := ICE_DAGGER_SKILL;

    AssistSkills[1] := CANCEL_SKILL;
    AssistSkills[2] := AURA_SYMPHONY_SKILL;
    AssistSkills[3] := SPELL_FORCE_SKILL;

    FlashSkills[1] := NOBLESS_SKILL;
    FlashSkills[2] := RESURECTION_SKILL;
    FlashSkills[3] := MASS_RESURECTION_SKILL;
    FlashSkills[4] := FOE_SKILL;
    FlashSkills[5] := ALI_CLEANSE;
    FlashSkills[6] := CELESTIAL_SHIELD;
    FlashSkills[7] := SPELL_FORCE_SKILL;

    PrintBotMsg('===========================');
    PrintBotMsg('Welcome to OTOMO v3.0');
    PrintBotMsg('Free Radar + Assister by LanGhost');
    PrintBotMsg('https://github.com/adrixfree');
    PrintBotMsg('Change your configs in settings.ini');
    PrintBotMsg('===========================');
end;

procedure AutoFlash();
var
    target: TL2Char;
    i: integer;
begin
    for i := 0 to CharList.Count - 1 do
    begin
        target := CharList.Items(i);
        if (not target.Dead) and (target.ClanID <> User.ClanID)
            and (User.DistTo(target) <= FLASH_DISTANCE) and (not target.IsMember)
        then begin
            if (target.Cast.EndTime > 0) and (IsFlashSkill(target.Cast.ID))
            then Engine.UseSkill(AURA_FLASH_SKILL, False, False);

            if (FindFoe) and (target.Cast.EndTime > 0)
                and (target.Cast.ID = FOE_SKILL)
            then begin
                Engine.SetTarget(target);
                PlaySound(script.Path + FOE_CAST_SOUND);
            end;
        end;
    end;
end;

procedure PartyBuffMM();
var
    buff: TL2Buff;
    player: TL2Char;
    i,j: integer;
begin
    for i := 0 to Party.Chars.Count - 1 do
    begin
        player := Party.Chars.Items(i);

        if (player.Dead)
        then continue;

        if (ResistAquaInCombat) or ((not ResistAquaInCombat) and (not User.InCombat))
        then begin
            if (PartyResistAqua)
            then begin
                if (not player.Buffs.ByID(SURRENDER_WATER_SKILL, buff))
                    and (not player.Buffs.ByID(RESIST_AQUA_BUFF, buff))
                    and (User.DistTo(player) <= RESIST_AQUA_DISTANCE)
                then begin
                    AssistStatus := false;
                    engine.SetTarget(player);
                    delay(300);
                    engine.UseSkill(RESIST_AQUA_BUFF);
                    delay(300);
                    AssistStatus := true;
                end;
            end;
        end;

        if (PartyWalkingScroll)
        then begin
            if ((player.AbnormalID and (1 shl (TRANCE_DEBUFF_BIT))) > 0)
                and (User.DistTo(player) <= WALKING_SCROLL_DISTANCE)
            then begin
                AssistStatus := false;
                engine.SetTarget(player);
                delay(300);
                engine.UseItem(WALkiNG_SCROLL_ITEM);
                delay(300);
                AssistStatus := true;
            end;
        end;

        if (PartyNobless)
        then begin
            if (not player.Buffs.ByID(NOBLESS_BUFF, buff))
                and (User.DistTo(player) <= NOBLESS_DISTANCE)
            then begin
                AssistStatus := false;
                engine.SetTarget(player);
                delay(300);
                engine.UseSkill(NOBLESS_BUFF);
                delay(300);
                AssistStatus := true;
            end;
        end;
    end;
end;

procedure AssistAttack();
var
    target: TL2Char;
    skill, chaos : TL2Skill;
    i, j: integer;
begin
    for i := 0 to PartyAssisters.Count - 1 do
    begin
        if (CharList.ByName(PartyAssisters[i], target))
        then begin
            if (not target.Dead) and (target.Target.Name <> target.Name)
            then break;
        end;
    end;

    for i := 1 to ASSIST_SKILLS_COUNT do
    begin
         if ((AssistSkills[i] = SOLAR_FLARE_SKILL) and (not AutoAttack))
         then continue;

        if ((target.Cast.ID = AssistSkills[i])
            and (target.Cast.EndTime > 0))
        then begin
            if (AssistSkills[i] = CANCEL_SKILL)
            then begin
                for j := 1 to ASSIST_SKILL_RETRIES do
                begin
                    delay(100);
                    Engine.GetSkillList.ByID(CANCEL_SKILL, skill);

                    if (ArcaneChaos)
                    then begin
                        Engine.GetSkillList.ByID(ARCANE_CHAOS_SKILL, chaos);
                        if (chaos.EndTime = 0)
                        then Engine.DUseSkill(ARCANE_CHAOS_SKILL, false, false)
                        else Engine.DUseSkill(CANCEL_SKILL, false, false);
                    end
                    else Engine.DUseSkill(CANCEL_SKILL, false, false);

                    if (skill.EndTime > 0) or (User.Dead)
                    then break;
                end;
            end else
            begin
                for j := 1 to ASSIST_SKILL_RETRIES do
                begin
                    delay(100);

                    Engine.GetSkillList.ByID(AssistSkills[i], skill);
                    Engine.DUseSkill(AssistSkills[i], false, false);

                    if (skill.EndTime > 0) or (User.Dead)
                    then break;
                end;
            end;
        end;
    end;
end;

procedure Resurrection();
var
    i: integer;
    buff: TL2Skill;
begin
    if (not User.Dead)
    then exit;

    AssistStatus := false;

    while (not User.Buffs.ByID(NOBLESS_BUFF, buff)) do
    begin
        if (not FastRes)
        then break;

        if (User.Dead) and (User.AbnormalID <= 2)
        then Engine.ConfirmDialog(true);

        Engine.SetTarget(User);
        Engine.DUseSkill(NOBLESS_BUFF, true, false);

        delay(200);
    end;

    AssistStatus := true;
end;

procedure FoundCancelEnd();
var
    skill: TL2Skill;
begin
    if (Engine.GetSkillList.ByID(CANCEL_SKILL, skill))
    then begin
        if (skill.EndTime > CANCEL_END_TIME)
        then FoundCancel := true;

        if (skill.EndTime <= CANCEL_END_TIME) and (FoundCancel)
        then begin
            FoundCancel := false;
            PlaySound(script.Path + CANCEL_END_SOUND);
        end;
    end;
end;

procedure SelfBuffArch();
var
    i : integer;
    buff, skill: TL2Skill;
begin
    for i := 1 to ARCH_BUFFS_COUNT do
    begin
        if (not User.Buffs.ByID(ArchBuffs[i], buff))
        then begin
            if (ArchBuffs[i] = DASH_BUFF) and (not AutoDash)
            then continue;

            if (ArchBuffs[i] = CRYSTAL_BUFF)
            then begin
                if (not Crystal)
                then continue;

                Engine.UseItem(CRYSTAL_ITEM);
                Delay(100);
                continue;
            end;

            if (ArchBuffs[i] = NOBLESS_BUFF)
            then begin
                Engine.SetTarget(User);
                Engine.UseSkill(NOBLESS_BUFF);
                Engine.CancelTarget;
                Delay(800);
                continue;
            end;

            if (ArchBuffs[i] = WIND_WALK_BUFF)
            then begin
                if (not User.Buffs.ByID(PAAGRIO_HASTE_BUFF, buff)) and
                    (not User.Buffs.ByID(HASTE_POTION_BUFF, buff))
                then begin
                    Engine.UseItem(HASTE_POTION_ITEM);
                    Delay(100);
                    continue;
                end;
            end;

            if (ArchBuffs[i] = HASTE_BUFF)
            then begin
                if (not User.Buffs.ByID(SWIFT_ATTACK_POTION_BUFF, buff))
                then begin
                    Engine.UseItem(SWIFT_ATTACK_POTION_ITEM);
                    Delay(100);
                    continue;
                end;
            end;

            Engine.UseSkill(ArchBuffs[i]);
            Delay(600);
        end;
    end;

    if (User.HP < ELEXIR_MIN_HP)
    then Engine.UseItem(ELEXIR_HP_ITEM);

    if (User.CP < ELEXIR_MIN_CP)
    then Engine.UseItem(ELEXIR_CP_ITEM);
end;

procedure SelfBuffMM();
var
    i : integer;
    buff : TL2Skill;
begin
    if (FastRes)
    then Resurrection();

    if (CheckCancel)
    then FoundCancelEnd();

    for i := 1 to MM_BUFFS_COUNT do
    begin
        if (not User.Buffs.ByID(MMBuffs[i], buff))
        then begin
            if (MMBuffs[i] = CRYSTAL_BUFF)
            then begin
                if (not Crystal)
                then continue;

                Engine.UseItem(CRYSTAL_ITEM);
                Delay(100);
                continue;
            end;

            if (MMBuffs[i] = RESIST_AQUA_BUFF)
            then begin
                if ((ResistAquaInCombat) or ((not ResistAquaInCombat) and (not User.InCombat)))
                    and (not IsRadar)
                then begin
                    if (not User.Buffs.ByID(SURRENDER_WATER_SKILL, buff))
                    then begin
                        AssistStatus := false;
                        delay(100);
                        Engine.SetTarget(User);
                        Engine.UseSkill(RESIST_AQUA_BUFF);
                        Delay(400);
                        AssistStatus := true;
                    end;
                end;
                continue;
            end;

            if (MMBuffs[i] = Integer(WIND_WALK_BUFF))
            then begin
                if (not User.Buffs.ByID(PAAGRIO_HASTE_BUFF, buff)) and
                    (not User.Buffs.ByID(HASTE_POTION_BUFF, buff))
                then begin
                    Engine.UseItem(HASTE_POTION_ITEM);
                    Delay(100);
                    continue;
                end;
            end;

            if (MMBuffs[i] = Integer(ACUMEN_BUFF))
            then begin
                if (not User.Buffs.ByID(WISDOM_PAAGRIO_BUFF, buff)) and
                    (not User.Buffs.ByID(MAGIC_HASTE_POTION_BUFF, buff))
                then begin
                    Engine.UseItem(MAGIC_HASTE_POTION_ITEM);
                    Delay(100);
                    continue;
                end;
            end;

            if (MMBuffs[i] = NOBLESS_BUFF)
            then begin
                AssistStatus := false;
                delay(100);
                Engine.SetTarget(User);
                Engine.UseSkill(NOBLESS_BUFF);
                Engine.CancelTarget;
                Delay(800);
                AssistStatus := true;
                continue;
            end;

            Engine.UseSkill(MMBuffs[i]);
            Delay(800);
        end;
    end;

    if (User.HP < ELEXIR_MIN_HP)
    then Engine.UseItem(ELEXIR_HP_ITEM);

    if (User.CP < ELEXIR_MIN_CP)
    then Engine.UseItem(ELEXIR_CP_ITEM);
end;

procedure RangeAttackMM();
var
    i : integer;
    skill, light, solar : TL2Skill;
begin
    if (AtkType = SURRENDER_ATTACK)
    then begin
        for i := 1 to RANGE_SKILLS_COUNT do
        begin
            if (not AutoAttack)
            then break;

            if (SurrRangeSkills[i] = ICE_DAGGER_SKILL)
                and (User.AtkSpd > MIN_CAST_SPD)
            then continue;

            AssistAttack();
            AutoFlash();

            Engine.GetSkillList.ByID(SurrRangeSkills[i], skill);
            Engine.GetSkillList.ByID(SOLAR_FLARE_SKILL, solar);

            if (SurrRangeSkills[i] = SURRENDER_WATER_SKILL)
            then begin
                // Cast Surrender only one time per target
                if (User.Target.Name <> LastTargetName)
                then begin
                    Engine.DUseSkill(SurrRangeSkills[i], False, False);
                    LastTargetName := User.Target.Name;
                    Delay(500);
                end;
                continue;
            end;

            // Cast Solar and Hydro
            if (skill.EndTime = 0) and (not User.Target.Dead)
            then  begin
                if (SurrRangeSkills[i] = HYDRO_BLAST_SKILL)
                    or (LightRangeSkills[i] = ICE_DAGGER_SKILL)
                then begin
                    if (solar.EndTime = 0)
                    then continue;
                end;
                Engine.DUseSkill(SurrRangeSkills[i], False, False);
                Delay(200);
            end;
        end;
    end
    else
    if (AtkType = LIGHT_ATTACK)
    then begin
        for i := 1 to RANGE_SKILLS_COUNT do
        begin
            if (not AutoAttack)
            then break;

            if (LightRangeSkills[i] = ICE_DAGGER_SKILL)
                and (User.AtkSpd > MIN_CAST_SPD)
            then continue;

            AssistAttack();
            AutoFlash();

            Engine.GetSkillList.ByID(LightRangeSkills[i], skill);
            Engine.GetSkillList.ByID(SOLAR_FLARE_SKILL, solar);
            Engine.GetSkillList.ByID(LIGHT_VORTEX_SKILL, light);

            if (not User.Target.Dead)
            then begin
                if (LightRangeSkills[i] = LIGHT_VORTEX_SKILL)
                then begin
                    if (solar.EndTime = 0)
                    then continue;
                end;

                if (LightRangeSkills[i] = HYDRO_BLAST_SKILL)
                    or (LightRangeSkills[i] = ICE_DAGGER_SKILL)
                then begin
                    if (solar.EndTime = 0) or (light.EndTime = 0)
                    then continue;
                end;
                Engine.DUseSkill(LightRangeSkills[i], False, False);
                Delay(200);
            end;
        end;
    end
    else
    if (AtkType = SOLAR_ATTACK)
    then begin
        for i := 1 to SOLAR_SKILLS_COUNT do
        begin
            if (not AutoAttack)
            then break;

            if (SolarRangeSkills[i] = ICE_DAGGER_SKILL)
                and (User.AtkSpd > MIN_CAST_SPD)
            then continue;

            AssistAttack();
            AutoFlash();

            Engine.GetSkillList.ByID(SolarRangeSkills[i], skill);
            Engine.GetSkillList.ByID(SOLAR_FLARE_SKILL, solar);

            if (skill.EndTime = 0) and (not User.Target.Dead)
            then  begin
                if (SolarRangeSkills[i] = HYDRO_BLAST_SKILL)
                    or (SolarRangeSkills[i] = ICE_DAGGER_SKILL)
                then begin
                    if (solar.EndTime = 0)
                    then continue;
                end;
                Engine.DUseSkill(SolarRangeSkills[i], False, False);
                Delay(200);
            end;
        end;
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
                    for i := 0 to PartyAssisters.Count - 1 do
                    begin
                        if (CharList.ByName(PartyAssisters[i], target))
                        then begin
                            if (not target.Dead) and (target.Target.Name <> target.Name)
                            then begin
                                Engine.DMoveTo(target.X, target.Y + 10, target.Z);
                                break;
                            end;
                        end;
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

procedure BuffsThread();
begin
    while true do
    begin
        try
            if (User.ClassID = MM_CLASS)
            then begin
                SelfBuffMM();
                if (not IsRadar)
                then PartyBuffMM();
            end
            else SelfBuffArch();
        except
            print('Fail to buff.');
        end;
        delay(10);
    end;
end;

procedure AssistThread();
var
    target: TL2Char;
    i: integer;
    status: boolean;
begin
    while true do
    begin
        try
            if (AssistStatus)
            then begin
                status := true;
                for i := 0 to PartyAssisters.Count - 1 do
                begin
                    if (CharList.ByName(PartyAssisters[i], target))
                    then begin
                        if (not target.Dead) and (target.Target.Name <> target.Name)
                        then begin
                            Engine.Assist(target.Name);
                            status := false;
                            break;
                        end;
                    end;
                end;
                IsRadar := status;
            end;
        except
            print('Fail to assist.');
        end;
        delay(300);
    end;
end;

procedure AttackThread();
var
    Assister: TL2Char;
begin
    while true do
    begin
        try
            if (AutoAttack)
            then begin
                if (User.ClassID = MM_CLASS)
                then RangeAttackMM()
                else Engine.Attack(ARCH_ATTACK_DELAY, false);
            end
            else begin
                if (User.ClassID = MM_CLASS)
                then begin
                    AssistAttack();
                    AutoFlash();
                    delay(100);
                end;
            end;
            delay(10);
        except
            print('Fail to attack.');
        end;
    end;
end;

procedure ReskillThread();
var
    p1, p2: pointer;
    enemy: TL2Live;
    target: TL2Char;
begin
    while True do
    begin
        try
            Engine.WaitAction([laRevive], p1, p2);
            enemy := TL2Live(p1);

            if (CharList.ByName(enemy.Name, target))
            then begin
                if (User.DistTo(target) <= StrToInt(RangeList[CurRange]))
                    and (not target.Dead) and (target.ClanID <> User.ClanID)
                    and (not target.IsMember)
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

                    Engine.SetTarget(target);

                    if (User.ClassID = MM_CLASS) and (ReskillSolar)
                    then Engine.DUseSkill(SOLAR_FLARE_SKILL, False, False);
                    Delay(ReskillDelay);
                end;
            end;
        except
            print('Fail to reskill');
        end;
        Delay(10);
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

procedure TargetSaveThread();
var
    Action: TL2Action;
    p1, p2: pointer;
    enemy: TL2Char;
begin
    while True do
    begin
        try
            Action := engine.WaitAction([laTarget], p1, p2);
            if (Action = laTarget)
            then begin
                if (User.Target <> CurTarget) then
                begin
                    PrevTarget := CurTarget;
                    CurTarget := User.Target;
                end;
            end;

            if (WarlordIgnore) and (IsRadar)
            then begin
                if (CharList.ByName(User.Target.Name, enemy))
                then begin
                    if (enemy.ClassID = WARLORD_CLASS)
                    then Engine.SetTarget(PrevTarget);
                end;
            end;
        except
            print('Fail to save target');
        end;
    end;
end;

procedure HoldTargetThread();
var
    p1, p2: pointer;
    Action: TL2Action;
    escBtn: boolean;
begin
    while true do
    begin
        try
            Action := Engine.WaitAction([laUnTarget, laKey], p1, p2);
            if (Action = laUnTarget)
            then begin
                if not (User.Target = CurTarget) and (not escBtn)
                then begin
                    delay(100);
                    Engine.SetTarget(CurTarget); 
                end; 
                delay(100);
                escBtn := false;
            end;

            if (Action = laKey) 
            then escBtn := (Integer(p1) = $1B);
        except
            print('Fail to hold target');
        end;
    end;
end;

procedure OnPacket(ID1, ID2: cardinal; Data: pointer; DataSize: word);
var
    player: TPlayer;
    i: integer;
begin
    try
        if (ID1 = $03)
        then begin
            player := TPlayer.Create(Data, DataSize);
            if (player.Team = 0)
            then begin
                for i := 0 to Assisters.Count - 1 do
                begin
                    if (Assisters[i] = player.Name)
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

procedure PartyThread();
var
    i: integer;
begin
    while true do
    begin
        try
            PartyList.Clear();
            for i := 0 to Party.Chars.Count - 1 do
            begin
                PartyList.Add(Party.Chars.Items(i).Name);
            end;
        except
            print('Fail to process party');
        end;
        delay(1000);
    end;
end;

procedure AssistersThread();
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
                    if (target.Cast.ID = SURRENDER_WATER_SKILL)
                    then begin
                        found := false;
                        for j := 0 to Assisters.Count - 1 do
                        begin
                            if (target.Name = Assisters[j])
                            then begin
                                found := true;
                                break;
                            end;
                        end;

                        if (not found)
                        then begin
                            if (Assisters.Count > MAX_ASSISTERS)
                            then Assisters.Delete(MAX_ASSISTERS);
                            Assisters.Insert(0, target.Name);
                        end;
                    end;
                end;
            end;
        except
            print('Fail to set title');
        end;
        delay(100);
    end;
end;

procedure TitlesThread();
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
                        if (target.Name = Assisters[j])
                        then begin
                            SendTitle(target.OID, '>>> ASSISTER <<<');
                            delay(10);
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

procedure FindTargetAfterKillThread();
var
    enemy: TL2Live;
    target: TL2Char;
    p1, p2: Pointer;
    i: integer;
begin
    while True do
    begin
        try
            if (not User.Dead) and (IsRadar)
            then begin
                Engine.WaitAction([laDie], p1, p2);
                enemy := TL2Live(p1);

                if (enemy.Name <> User.Target.Name)
                then continue;

                PrintBotMsg('Target "' + enemy.Name + '" was killed. Find next.');
                if (DeadSound) then PlaySound(script.Path + DEAD_SOUND);

                if (FindAfterKill)
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
                end;
                Delay(1000);
            end;
        except
            print('Fail to find target after kill.');
        end;
        delay(10);
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
    script.NewThread(@TitlesThread);
    script.NewThread(@AssistersThread);
    script.NewThread(@FindTargetAfterKillThread);
    script.NewThread(@PartyThread);
end.