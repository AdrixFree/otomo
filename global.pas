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
    TProfile = (MM_PROFILE, ARCH_PROFILE, NECR_PROFILE, PP_PROFILE);

const
	GLOB_MOD = 0;
	procedure GlobalInit();

var
    IsRadar: boolean;
    UserProfile: TProfile;
    ExcludedClans: TStringList;

implementation

procedure GlobalInit();
begin
    ExcludedClans := TStringList.Create();
end;

end.