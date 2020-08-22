///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit Reskill;

interface

uses
	Target, Helpers, SysUtils;

const
	RESKILL_MOD = 0;

	procedure ReskillThread();

var
	ReskillDelay: integer;
    ReskillSolar: boolean;

implementation

///////////////////////////////////////////////////////////
//
//                      MODULE THREADS
//
///////////////////////////////////////////////////////////

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

end.