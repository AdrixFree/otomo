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
    Helpers, Assist, Classes, Global, Packets;

type
    AttackType = (SURRENDER_ATTACK, LIGHT_ATTACK, ICE_ATTACK, SOLAR_ATTACK);

const
    FOE_CAST_SOUND = 'sound/foe.wav';

    RANGE_SKILLS_COUNT = 4;
    SOLAR_SKILLS_COUNT = 3;
    FLASH_SKILLS_COUNT = 7;

    FLASH_SKILL_RETRIES = 20;
    ARCH_ATTACK_DELAY = 500;
    MIN_CAST_SPD = 1671;
    FLASH_DISTANCE = 200;

    procedure AttackInit();
    procedure AttackThread();
    procedure AutoFlashThread();
    procedure AutoFlashPacket(Data: pointer; DataSize: word);

var
    LastTargetName: string;
    AutoAttack: boolean;
    AtkType: AttackType;
    FindFoe: boolean;
    FlashUsers: TList;
    SurrRangeSkills: array[1..RANGE_SKILLS_COUNT] of integer;
    LightRangeSkills: array[1..RANGE_SKILLS_COUNT] of integer;
    IceRangeSkills: array[1..RANGE_SKILLS_COUNT] of integer;
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
    FlashUsers := TList.Create();

    SurrRangeSkills[1] := SURRENDER_WATER_SKILL;
    SurrRangeSkills[2] := SOLAR_FLARE_SKILL;
    SurrRangeSkills[3] := HYDRO_BLAST_SKILL;
    SurrRangeSkills[4] := ICE_DAGGER_SKILL;

    LightRangeSkills[1] := SOLAR_FLARE_SKILL;
    LightRangeSkills[2] := LIGHT_VORTEX_SKILL;
    LightRangeSkills[3] := HYDRO_BLAST_SKILL;
    LightRangeSkills[4] := ICE_DAGGER_SKILL;

    IceRangeSkills[1] := SOLAR_FLARE_SKILL;
    IceRangeSkills[2] := ICE_VORTEX_SKILL;
    IceRangeSkills[3] := HYDRO_BLAST_SKILL;
    IceRangeSkills[4] := ICE_DAGGER_SKILL;

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

procedure AutoFlashPacket(Data: pointer; DataSize: word);
var
    packet: TNetworkPacket;
    oid, skill, i: cardinal;
begin
    packet := TNetworkPacket.Create(Data, DataSize);
    oid := packet.ReadD();
    packet.ReadD();
    skill := packet.ReadD();
    packet.Free();

    for i := 1 to FLASH_SKILLS_COUNT do
    begin
        if (skill = FlashSkills[i])
        then begin
            FlashUsers.Add(Pointer(oid));
            exit;
        end;
    end;
end;

///////////////////////////////////////////////////////////
//
//                     PRIVATE FUNCTIONS
//
///////////////////////////////////////////////////////////

procedure RangeAttackMM();
var
    i : integer;
    skill, light, solar, ice : TL2Skill;
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
    if (AtkType = ICE_ATTACK)
    then begin
        for i := 1 to RANGE_SKILLS_COUNT do
        begin
            if (not AutoAttack)
            then break;

            if (IceRangeSkills[i] = ICE_DAGGER_SKILL)
                and (User.AtkSpd > MIN_CAST_SPD)
            then continue;

            Engine.GetSkillList.ByID(IceRangeSkills[i], skill);
            Engine.GetSkillList.ByID(SOLAR_FLARE_SKILL, solar);
            Engine.GetSkillList.ByID(ICE_VORTEX_SKILL, ice);

            if (not User.Target.Dead)
            then begin
                if (IceRangeSkills[i] = ICE_VORTEX_SKILL)
                then begin
                    if (solar.EndTime = 0)
                    then continue;
                end;

                if (IceRangeSkills[i] = HYDRO_BLAST_SKILL)
                    or (IceRangeSkills[i] = ICE_DAGGER_SKILL)
                then begin
                    if (solar.EndTime = 0) or (ice.EndTime = 0)
                    then continue;
                end;
                Engine.DUseSkill(IceRangeSkills[i], False, False);
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

procedure AutoFlashThread();
var
    target: TL2Char;
    i, j: integer;
    skill: TL2Skill;
begin
    while true do
    begin
        if (UserProfile <> MM_PROFILE)
        then begin
            delay(100);
            continue;
        end;

        try
            for i := 0 to FlashUsers.Count - 1 do
            begin
                if (i > FlashUsers.Count - 1)
                then break;

                if (CharList.ByOID(Cardinal(FlashUsers[i]), target))
                then begin
                    if (not target.Dead) and (target.ClanID <> User.ClanID)
                        and (User.DistTo(target) <= FLASH_DISTANCE) and (not target.IsMember)
                    then begin
                        for j := 1 to FLASH_SKILL_RETRIES do
                        begin
                            delay(100);

                            Engine.GetSkillList.ByID(AURA_FLASH_SKILL, skill);
                            Engine.DUseSkill(AURA_FLASH_SKILL, false, false);

                            if (skill.EndTime > 0) or (User.Dead)
                            then break;
                        end;
                    end;
                end;
                FlashUsers.Delete(i);
            end;
        except
            print('Fail to autoflash');
        end;
        delay(50);
    end;
end;

procedure AttackThread();
var
    Assister: TL2Char;
    i: integer;
    excluded: boolean;
begin
    while true do
    begin
        try
            if (AutoAttack)
            then begin
                excluded := false;
                for i := 0 to ExcludedClans.Count - 1 do
                begin
                    if (ExcludedClans[i] = User.Target.Clan)
                    then begin
                        excluded := true;
                        delay(100);
                        break;
                    end;
                end;

                if (excluded)
                then continue;

                if (UserProfile = MM_PROFILE)
                then RangeAttackMM();
                
                if (UserProfile = ARCH_PROFILE)
                then Engine.Attack(ARCH_ATTACK_DELAY, false);
            end;
            delay(10);
        except
            print('Fail to attack.');
        end;
    end;
end;

end.