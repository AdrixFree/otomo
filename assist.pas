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
    Helpers, Classes, Global, Packets;

const
    ASSIST_SKILLS_COUNT = 4;
    ASSIST_SKILL_RETRIES = 30;

    procedure AssistInit();
    procedure AssistThread();
    procedure AssistAttackThread();
    procedure AssistPacket(Data: pointer; DataSize: word);

type
    TAssistSpell = class
    public
        constructor Create(o: cardinal; s: cardinal);
        function GetOID(): cardinal;
        function GetSkill(): cardinal;
    private
        OID: cardinal;
        Skill: cardinal;
    end;

var
    AssistStatus: boolean = true;
    AssistSpells: TList;
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
    AssistSpells := TList.Create();

    AssistSkills[1] := CANCEL_SKILL;
    AssistSkills[2] := AURA_SYMPHONY_SKILL;
    AssistSkills[3] := SPELL_FORCE_SKILL;
    AssistSkills[4] := ARCANE_CHAOS_SKILL;
end;

procedure AssistPacket(Data: pointer; DataSize: word);
var
    packet: TNetworkPacket;
    oid, skill, i: cardinal;
    spell: TAssistSpell;
begin
    packet := TNetworkPacket.Create(Data, DataSize);
    oid := packet.ReadD();
    packet.ReadD();
    skill := packet.ReadD();
    packet.Free();

    for i := 1 to ASSIST_SKILLS_COUNT do
    begin
        if (skill = AssistSkills[i])
        then begin
            spell := TAssistSpell.Create(oid, skill);
            AssistSpells.Add(Pointer(spell));
            exit;
        end;
    end;
end;

///////////////////////////////////////////////////////////
//
//                     UNIT THREADS
//
///////////////////////////////////////////////////////////

procedure AssistAttackThread();
var
    target: TL2Char;
    skill, chaos : TL2Skill;
    i, j, k: integer;
begin
    while true do
    begin
        try
            for i := 0 to PartyAssisters.Count - 1 do
            begin
                if (CharList.ByName(PartyAssisters[i], target))
                then begin
                    if (not target.Dead) and (target.Target.Name <> target.Name)
                    then begin
                        for j := 0 to AssistSpells.Count - 1 do
                        begin
                            if (j > AssistSpells.Count - 1)
                            then break;

                            if (target.OID = TAssistSpell(AssistSpells[j]).GetOID())
                            then begin
                                if (TAssistSpell(AssistSpells[j]).GetSkill() = CANCEL_SKILL)
                                    or (TAssistSpell(AssistSpells[j]).GetSkill() = ARCANE_CHAOS_SKILL)
                                then begin
                                    for k := 1 to ASSIST_SKILL_RETRIES do
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
                                    for k := 1 to ASSIST_SKILL_RETRIES do
                                    begin
                                        delay(100);

                                        Engine.GetSkillList.ByID(TAssistSpell(AssistSpells[j]).GetSkill(), skill);
                                        Engine.DUseSkill(TAssistSpell(AssistSpells[j]).GetSkill(), false, false);

                                        if (skill.EndTime > 0) or (User.Dead)
                                        then break;
                                    end;
                                end;
                            end;

                            TAssistSpell(AssistSpells[j]).Free();
                            AssistSpells.Delete(j);
                        end;
                        break;
                    end;
                end;
            end;
        except
            print('Fail to assist attack')
        end;
        delay(50);
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
                            and (not IgnoreAssister)
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

///////////////////////////////////////////////////////////
//
//                    PRIVATE FUNCTIONS
//
///////////////////////////////////////////////////////////

constructor TAssistSpell.Create(o: cardinal; s: cardinal);
begin
    inherited Create;

    OID := o;
    Skill := s;
end;

function TAssistSpell.GetOID(): cardinal;
begin
    result := OID;
end;

function TAssistSpell.GetSkill(): cardinal;
begin
    result := Skill;
end;

end.