///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit Target;

interface

uses
    Helpers, Classes, Global;

const
    DEAD_SOUND = 'sound/dead.wav';

    procedure TargetInit();
    procedure TargetSaveThread();
    procedure HoldTargetThread();
    procedure FindTargetAfterKillThread();

var
    CurTarget, PrevTarget: TL2Live;
    WarlordIgnore: boolean = false;
    RangeList, ClassList, ClanList: TStringList;
    CurRange, CurClass, CurClan: integer;
    DeadSound: boolean;
    FindAfterKill: boolean;
    LastTargetName: string;

implementation

///////////////////////////////////////////////////////////
//
//                     PUBLIC FUNCTIONS
//
///////////////////////////////////////////////////////////

procedure TargetInit();
begin
    RangeList := TStringList.Create();
    ClassList := TStringList.Create();
    ClanList := TStringList.Create();

    CurRange := 0;
    CurClass := 0;
    CurClan := 0;

    ClassList.Add('ALL');
    ClassList.Add('MM');
    ClassList.Add('BP');

    ClanList.Add('ALL');
end;

///////////////////////////////////////////////////////////
//
//                      MODULE THREADS
//
///////////////////////////////////////////////////////////

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

procedure FindTargetAfterKillThread();
var
    enemy: TL2Live;
    target: TL2Char;
    p1, p2: Pointer;
    i, j: integer;
    excluded: boolean;
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
                end;
                Delay(1000);
            end;
        except
            print('Fail to find target after kill.');
        end;
        delay(10);
    end;
end;


end.