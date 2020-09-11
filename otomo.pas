///////////////////////////////////////////////////////////
//
//                          OTOMO
//               Radar + Assit for Interlude
//                  by LanGhost (c) 2020
//
///////////////////////////////////////////////////////////

uses
    Packets, Helpers, Players, Settings, Classes, Backlight,
    Buffs, Attack, Assist, Global, Target, Reskill, UI, Keyboard,
    Configs;

const
    CFG_FILE_NAME = 'settings.ini';
    RADAR_MODE_SOUND = 'sound/radar.wav';
    ASSISTER_MODE_SOUND = 'sound/assist.wav';

var
    Sets: TSettings;
    RadarSound: boolean;
    AssistSound: boolean;

///////////////////////////////////////////////////////////
//
//                   PUBLIC FUNCTIONS
//
///////////////////////////////////////////////////////////

procedure Init();
begin
    Sets := TSettings.Create(script.Path + CFG_FILE_NAME);

    GlobalInit();
    BackLightInit();
    BuffsInit();
    AttackInit();
    AssistInit();
    TargetInit();

    PrintBotMsg('===========================');
    PrintBotMsg('Welcome to OTOMO v3.6');
    PrintBotMsg('Free Radar + Assister by LanGhost');
    PrintBotMsg('https://github.com/adrixfree');
    PrintBotMsg('Change your configs in settings.ini');
    PrintBotMsg('===========================');

    if (User.ClassID = MM_CLASS) and (UserProfile <> MM_PROFILE)
    then begin
        UserProfile := MM_PROFILE;
        PrintBotMsg('Selected profile: MM');
    end;

    if (User.ClassID = ARCHER_CLASS) and (UserProfile <> ARCH_PROFILE)
        or (User.ClassID = GHOST_SENTINEL_CLASS)
        or (User.ClassID = MOONLIGHT_SENTINEL_CLASS)
    then begin
        UserProfile := ARCH_PROFILE;
        PrintBotMsg('Selected profile: ARCHER');
    end;
end;

///////////////////////////////////////////////////////////
//
//                  OVERRIDE FUNCTIONS
//
///////////////////////////////////////////////////////////

procedure OnPacket(ID1, ID2: cardinal; Data: pointer; DataSize: word);
begin
    if (ID1 = CHAR_INFO_PACKET) or (ID1 = MAGIC_SKILL_USE_PACKET)
    then BackLightPacket(ID1, Data, DataSize);

    if (ID1 = MAGIC_SKILL_USE_PACKET)
    then begin
        AutoFlashPacket(Data, DataSize);
        AssistPacket(Data, DataSize);
    end;
end;

///////////////////////////////////////////////////////////
//
//                       SCRIPT THREADS
//
///////////////////////////////////////////////////////////

procedure StatusThread();
var
    last: boolean;
begin
    last := false;

    while True do
    begin
        if (not User.Dead)
        then begin
            if (IsRadar and not last)
            then begin
                if (RadarSound) then PlaySound(script.Path + RADAR_MODE_SOUND);
                last := true;
                PrintBotMsg('Switch to RADAR mode');
            end;

            if (not IsRadar and last)
            then  begin
                if (AssistSound) then PlaySound(script.Path + ASSISTER_MODE_SOUND);
                last := false;
                PrintBotMsg('Switch to ASSIST mode');
            end;
        end;
        delay(500);
    end;
end;

procedure MoveToAssisterThread();
var
    i: integer;
    target: TL2Char;
begin
    while true do
    begin
        if (IsMoveToAssister) and (not IsRadar)
        then begin
            for i := 0 to PartyAssisters.Count - 1 do
            begin
                if (CharList.ByName(PartyAssisters[i], target))
                then begin
                    if (not target.Dead) and (target.Target.Name <> target.Name)
                    then begin
                        Engine.DMoveTo(target.X - (5+ Random(10)), target.Y + (5 + Random(10)), target.Z);
                        break;
                    end;
                end;
            end;
        end;
        delay(300);
    end;
end;

///////////////////////////////////////////////////////////
//
//                      MAIN FUNCTION
//
///////////////////////////////////////////////////////////

begin
    Init();
    LoadConfigs(Script.Path + CFG_FILE_NAME);

    script.NewThread(@AssistThread);
    script.NewThread(@BuffsThread);
    script.NewThread(@AttackThread);
    script.NewThread(@KeysThread);
    script.NewThread(@ReskillThread);
    script.NewThread(@StatusThread);
    script.NewThread(@TargetSaveThread);
    script.NewThread(@HoldTargetThread);
    script.NewThread(@BackLightTitlesThread);
    script.NewThread(@FindTargetAfterKillThread);
    script.NewThread(@BackLightPartyThread);
    script.NewThread(@RunUIThread);
    script.NewThread(@MoveToAssisterThread);
    script.NewThread(@AutoFlashThread);
    script.NewThread(@AssistAttackThread());
end.