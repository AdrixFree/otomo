///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit Keyboard;

interface

uses
    Global, Attack, Helpers, Buffs, Assist, Classes, Target,
    Reskill;

const
    KEY_MOD = 0;
    procedure KeysThread();

var
    AAKey, FRKey, CKey, MAKey: Char;
    NTKey, RRKey, NCSKey, NCKey, WIKey: Char;
    IsAutoAttack: boolean;
    IsMoveToAssister: boolean;

implementation

///////////////////////////////////////////////////////////
//
//                      MODULE THREADS
//
///////////////////////////////////////////////////////////

procedure KeysThread();
var
    p1, p2: Pointer;
    i, j: integer;
    excluded: boolean;
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

                            excluded := false;
                            for j := 0 to ExcludedClans.Count - 1 do
                            begin
                                if (ExcludedClans[j] = target.Clan)
                                then begin
                                    excluded := true;
                                    delay(100);
                                    break;
                                end;
                            end;

                            if (excluded)
                            then continue;

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

end.