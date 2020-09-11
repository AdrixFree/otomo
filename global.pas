///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

unit Global;

interface

uses
    Classes;

type
    TProfile = (MM_PROFILE, ARCH_PROFILE, NECR_PROFILE, PP_PROFILE, UNKNOWN_PROFILE);

const
	GLOB_MOD = 0;
	procedure GlobalInit();

var
    IsRadar: boolean;
    UserProfile: TProfile;
    ExcludedClans: TStringList;
    IgnoreAssister: boolean = false;
    RangeAttack: boolean = true;

implementation

procedure GlobalInit();
begin
    ExcludedClans := TStringList.Create();
    UserProfile := UNKNOWN_PROFILE;
end;

end.