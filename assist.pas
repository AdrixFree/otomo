///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit Assist;

interface

uses
    Helpers, Classes, Global;

const
    ASSIST_SKILLS_COUNT = 3;
    ASSIST_SKILL_RETRIES = 30;

    procedure AssistInit();
    procedure AssistThread();
    procedure AssistAttack();

var
    AssistStatus: boolean = true;
    PartyAssisters: TStringList;
    ArcaneChaos: boolean;
    AssistSkills: array[1..ASSIST_SKILLS_COUNT] of integer;

implementation

///////////////////////////////////////////////////////////
//
//                    PUBLIC FUNCTIONS
//
///////////////////////////////////////////////////////////

procedure AssistInit();
begin
    PartyAssisters := TStringList.Create();

    AssistSkills[1] := CANCEL_SKILL;
    AssistSkills[2] := AURA_SYMPHONY_SKILL;
    AssistSkills[3] := SPELL_FORCE_SKILL;
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
         if (AssistSkills[i] = SOLAR_FLARE_SKILL)
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

///////////////////////////////////////////////////////////
//
//                     UNIT THREADS
//
///////////////////////////////////////////////////////////

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

end.