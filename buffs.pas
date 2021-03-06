///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit Buffs;

interface

uses
    Helpers, Assist, Global, Attack;

const
    CANCEL_END_SOUND = 'sound/cancel.wav';
    ELEXIR_MIN_HP = 15;
    ELEXIR_MIN_CP = 15;
    CANCEL_END_TIME = 2;
    MM_BUFFS_COUNT = 5;
    ARCH_BUFFS_COUNT = 8;
    BUFF_RETRIES = 10;
    RESIST_AQUA_DISTANCE = 400;
    NOBLESS_DISTANCE = 400;
    WALKING_SCROLL_DISTANCE = 400;
    TRANCE_DEBUFF_BIT = 7;

    procedure BuffsInit();
    procedure BuffsThread();

var
    FastRes: boolean;
    FoundCancel: boolean;
    Crystal: boolean;
    PartyWalkingScroll: boolean;
    PartyResistAqua: boolean;
    ResistAquaInCombat: boolean;
    CheckCancel: boolean;
    PartyNobless: boolean;
    FlashAfterRes: boolean;
    AutoDash: boolean;
    ArchBuffs : array[1..ARCH_BUFFS_COUNT] of integer;
    MMBuffs: array[1..MM_BUFFS_COUNT] of integer;

implementation

///////////////////////////////////////////////////////////
//
//                    PUBLIC FUNCTIONS
//
///////////////////////////////////////////////////////////

procedure BuffsInit();
begin
    MMBuffs[1] := ARCANE_BUFF;
    MMBuffs[2] := CRYSTAL_BUFF;
    MMBuffs[3] := RESIST_AQUA_BUFF;
    MMBuffs[4] := WIND_WALK_BUFF;
    MMBuffs[5] := ACUMEN_BUFF;

    ArchBuffs[1] := RAPID_SHOT_BUFF;
    ArchBuffs[2] := CRYSTAL_BUFF;
    ArchBuffs[3] := STANCE_BUFF;
    ArchBuffs[4] := ACCURACY_BUFF;
    ArchBuffs[5] := DASH_BUFF;
    ArchBuffs[6] := BLESSING_SAGITARIUS_BUFF;
    ArchBuffs[7] := HASTE_BUFF;
    ArchBuffs[8] := WIND_WALK_BUFF;
end;

///////////////////////////////////////////////////////////
//
//                    PRIVATE FUNCTIONS
//
///////////////////////////////////////////////////////////

procedure BuffsPartyMM();
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
                engine.UseSkill(NOBLESS_BUFF);
                delay(300);
                AssistStatus := true;
            end;
        end;
    end;
end;

procedure BuffsSelfArch();
var
    i, j : integer;
    buff, skill: TL2Skill;
begin
    for i := 1 to ARCH_BUFFS_COUNT do
    begin
        for j := 0 to BUFF_RETRIES do
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
                Delay(400);
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
            Delay(400);
        end
        else break;
        delay(100);
        end;
    end;

    if (User.HP < ELEXIR_MIN_HP) and (not User.Dead)
    then Engine.UseItem(ELEXIR_HP_ITEM);

    if (User.CP < ELEXIR_MIN_CP) and (not User.Dead)
    then Engine.UseItem(ELEXIR_CP_ITEM);
end;

procedure BuffsSelfMM();
var
    i, j : integer;
    buff : TL2Skill;
begin
    if (CheckCancel)
    then FoundCancelEnd();

    for i := 1 to MM_BUFFS_COUNT do
    begin
        for j := 0 to BUFF_RETRIES do
        begin
            if (User.Dead)
            then Resurrection();

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
                            Delay(100);
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

                Engine.UseSkill(MMBuffs[i]);
                Delay(400);
            end
            else break;
            delay(100);
        end;
    end;

    if (User.HP < ELEXIR_MIN_HP) and (not User.Dead)
    then Engine.UseItem(ELEXIR_HP_ITEM);

    if (User.CP < ELEXIR_MIN_CP) and (not User.Dead)
    then Engine.UseItem(ELEXIR_CP_ITEM);
end;

procedure Resurrection();
var
    i, cnt: integer;
    buff: TL2Skill;
    target: TL2Char;
    lastRadar: boolean;
    lastAttack: boolean;
begin
    AssistStatus := false;
    lastRadar := IsRadar;
    lastAttack := AutoAttack;
    IsRadar := false;
    AutoAttack := false;
    cnt := 0;

    while (not User.Buffs.ByID(NOBLESS_BUFF, buff)) do
    begin
        if (User.Dead) and (User.AbnormalID <= 2) and (FastRes)
        then Engine.ConfirmDialog(true);

        Engine.SetTarget(User);
        Engine.DUseSkill(NOBLESS_BUFF, false, false);

        if (FlashAfterRes)
        then begin
            for i := 0 to CharList.Count - 1 do
            begin
                target := CharList.Items(i);
                if (User.DistTo(target) <= 150) and (User.ClanID <> target.ClanID)
                    and (not target.IsMember)
                then begin
                    cnt := cnt + 1;
                    if (cnt >= 2)
                    then begin
                        Engine.DUseSkill(AURA_FLASH_SKILL, false, false);
                        cnt := 0;
                        break;
                    end;
                end;
            end;
        end;

        delay(200);
    end;

    AssistStatus := true;
    IsRadar := lastRadar;
    AutoAttack := lastAttack;
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

///////////////////////////////////////////////////////////
//
//                       SCRIPT THREADS
//
///////////////////////////////////////////////////////////

procedure BuffsThread();
begin
    while true do
    begin
        try
            if (UserProfile = MM_PROFILE)
            then begin
                BuffsSelfMM();
                if (not IsRadar)
                then BuffsPartyMM();
            end;

            if (UserProfile = ARCH_PROFILE)
            then BuffsSelfArch();
        except
            print('Fail to buff.');
        end;
        delay(10);
    end;
end;

end.