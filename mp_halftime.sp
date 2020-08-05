#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

bool firsthalf = false;
bool swap = false;

public Plugin myinfo =
{
    name = "[CS:S] mp_halftime",
    author = "GabenNewell (Bad Kitty)",
    description = "Determines whether the match switches sides in a halftime event.",
    version = "2.0.0",
    url = "https://forums.alliedmods.net/showthread.php?t=241716"
};

public void OnPluginStart()
{
    CreateConVar("mp_halftime", "1", "Determines whether the match switches sides in a halftime event.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if ((CS_GetTeamScore(2) + CS_GetTeamScore(3)) == 0)
    {
        firsthalf = true;
    }
    
    if (GetConVarBool(FindConVar("mp_halftime")) && swap)
    {
        int startmoney = GetConVarInt(FindConVar("mp_startmoney"));

        for (int client = 1; client <= MaxClients; client++)
        {
            if (IsClientInGame(client) && GetClientTeam(client) > 1)
            {
                for (int weapon, i = 0; i < 5; i++)
                {
                    if (i != 2 && i != 4)
                    {
                        while ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
                        {
                            RemovePlayerItem(client, weapon);
                        }
                    }
                }
                
                GivePlayerItem(client, (GetClientTeam(client) == 2) ? "weapon_glock" : "weapon_usp");
                
                SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
                SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
                SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);
                SetEntProp(client, Prop_Send, "m_iAccount", startmoney);
            }
        }

        swap = false;
    }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (GetConVarBool(FindConVar("mp_halftime")) && firsthalf)
    {
        int maxrounds = GetConVarInt(FindConVar("mp_maxrounds"));
        int timeleft;
        int timelimit;
        GetMapTimeLeft(timeleft);
        GetMapTimeLimit(timelimit);
        
        if ((maxrounds != 0 && (CS_GetTeamScore(2) + CS_GetTeamScore(3)) == (maxrounds / 2)) || (timelimit != 0 && timeleft <= (timelimit * 30)))
        {
            for (int client = 1; client <= MaxClients; client++)
            {
                if (IsClientInGame(client) && GetClientTeam(client) > 1)
                {
                    CS_SwitchTeam(client, (GetClientTeam(client) == 2) ? 3 : 2);
                }
            }
            
            int tmp = CS_GetTeamScore(2);
            CS_SetTeamScore(2, CS_GetTeamScore(3));
            CS_SetTeamScore(3, tmp);
            
            SetTeamScore(2, CS_GetTeamScore(2));
            SetTeamScore(3, CS_GetTeamScore(3));
            
            swap = true;
            firsthalf = false;
        }
    }
}
