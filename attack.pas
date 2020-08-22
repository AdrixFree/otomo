///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit Attack;

interface

uses
	Helpers, Assist, Classes;

type
    AttackType = (SURRENDER_ATTACK, LIGHT_ATTACK, SOLAR_ATTACK);

const
	FOE_CAST_SOUND = 'sound/foe.wav';

	RANGE_SKILLS_COUNT = 4;
    SOLAR_SKILLS_COUNT = 3;
    FLASH_SKILLS_COUNT = 7;

    ARCH_ATTACK_DELAY = 500;

    MIN_CAST_SPD = 1671;

    FLASH_DISTANCE = 200;

    procedure AttackInit();
    procedure AttackThread();

var
	LastTargetName: string;
    AutoAttack: boolean;
    AtkType: AttackType;
    FindFoe: boolean;
    SurrRangeSkills: array[1..RANGE_SKILLS_COUNT] of integer;
    LightRangeSkills: array[1..RANGE_SKILLS_COUNT] of integer;
    SolarRangeSkills: array[1..SOLAR_SKILLS_COUNT] of integer;
    FlashSkills: array[1..FLASH_SKILLS_COUNT] of integer;

implementation

///////////////////////////////////////////////////////////
//
//                       PUBLIC FUNCTIONS
//
///////////////////////////////////////////////////////////

procedure AttackInit();
begin
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

    FlashSkills[1] := NOBLESS_SKILL;
    FlashSkills[2] := RESURECTION_SKILL;
    FlashSkills[3] := MASS_RESURECTION_SKILL;
    FlashSkills[4] := FOE_SKILL;
    FlashSkills[5] := ALI_CLEANSE;
    FlashSkills[6] := CELESTIAL_SHIELD;
    FlashSkills[7] := SPELL_FORCE_SKILL;
end;

///////////////////////////////////////////////////////////
//
//                     PRIVATE FUNCTIONS
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
//                       UNIT THREADS
//
///////////////////////////////////////////////////////////

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

end.