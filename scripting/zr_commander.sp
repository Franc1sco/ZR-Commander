#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <zombiereloaded>
#include <zrcommander>

#pragma newdecls required // let's go new syntax! 

#define PLUGIN_VERSION   "1.0"

int Commander = -1;
Handle g_fward_onBecome;
Handle g_fward_onBecomePre;
Handle g_fward_onLeft;

public Plugin myinfo = {
	name = "ZR Commander",
	author = "Franc1sco",
	description = "ZR commander script",
	version = PLUGIN_VERSION,
	url = "http://git.tf/Franc1sco/ZR-Commander"
};

public void OnPluginStart() 
{
	RegConsoleCmd("sm_c", BecomeCommander);
	RegConsoleCmd("sm_commander", BecomeCommander);
	RegConsoleCmd("sm_uc", ExitCommander);
	RegConsoleCmd("sm_uncommander", ExitCommander);
	
	RegAdminCmd("sm_rc", RemoveCommander, ADMFLAG_GENERIC);
	
	HookEvent("round_start", roundStart);
	HookEvent("player_death", playerDeath); 

	CreateConVar("zr_commander_version", PLUGIN_VERSION,  "Plugin version", FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("zrc_exist", Native_ExistCommander);
	CreateNative("zrc_is", Native_IsCommander);
	CreateNative("zrc_set", Native_SetCommander);
	CreateNative("zrc_remove", Native_RemoveCommander);
	CreateNative("zrc_get", Native_GetCommander);
	
	g_fward_onBecome = CreateGlobalForward("zrc_OnCommanderCreated", ET_Ignore, Param_Cell);
	g_fward_onLeft = CreateGlobalForward("zrc_OnCommanderLeft", ET_Ignore, Param_Cell);
	
	g_fward_onBecomePre = CreateGlobalForward("zrc_OnCommanderCreate", ET_Hook, Param_Cell);

	RegPluginLibrary("zrcommander");
	
	
	return APLRes_Success;
}

public Action BecomeCommander(int client,int args) 
{
	if (Commander == -1) 
	{
		if (IsPlayerAlive(client)) 
		{
			if (ZR_IsClientHuman(client))
			{
				SetTheCommander(client);
			}
			else 
			{
				CPrintToChat(client, " {darkred}[zrc]{default} You need to be human the commander");
			}
		}
		else 
		{
			CPrintToChat(client, " {darkred}[zrc]{default} You need to be alive for be the commander");
		}
	}
	else 
	{
		CPrintToChat(client, " {darkred}[zrc]{default} Already exist a commander");
	}
}

public Action ExitCommander(int client, int args) 
{
	if(client == Commander) 
	{
		RemoveTheCommander(client);
	}
	else 
	{
		CPrintToChat(client, " {darkred}[zrc]{default} You are not the commander");
	}
}

public Action roundStart(Handle event, char[] name, bool dontBroadcast) 
{
	Commander = -1; 
}

public Action playerDeath(Handle event, char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client == Commander)
	{
		RemoveTheCommander(client);
	}
}

public void OnClientDisconnect(int client)
{
	if(client == Commander) 
	{
		RemoveTheCommander(client);
	}
}

public Action RemoveCommander(int client,int args)
{
	if(Commander != -1) 
	{
		RemoveTheCommander(client);
	}
	else
	{
		CPrintToChatAll(" {darkred}[zrc]{default} Not exist a commander");
	}

	return Plugin_Handled; 
}

public void SetTheCommander(int client)
{
	Action result;
	result = Forward_OnCommanderCreationPre(client);
	
	switch (result)
	{
		case Plugin_Handled, Plugin_Stop :
		{
			return;
		}
	}
	
	Commander = client;
	CPrintToChatAll(" {darkred}[zrc]{default} The commander is %N", Commander);
	Forward_OnCommanderCreation(client);
}

public void RemoveTheCommander(int client)
{
	CPrintToChatAll(" {darkred}[zrc]{default} %N left the commander position", Commander);
	Commander = -1;
	
	Forward_OnCommanderLeft(client);
}

public int Native_ExistCommander(Handle plugin, int numParams)
{
	if(Commander != -1)
		return true;
	
	return false;
}

public int Native_GetCommander(Handle plugin, int numParams)
{
	return Commander;
}

public int Native_IsCommander(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsClientInGame(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if(client == Commander)
		return true;
	
	return false;
}

public int Native_SetCommander(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || !ZR_IsClientHuman(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if(Commander == -1)
	{
		SetTheCommander(client);
	}
}

public int Native_RemoveCommander(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsClientInGame(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if(client == Commander)
	{
		RemoveTheCommander(client);
	}
}

public void Forward_OnCommanderCreation(int client)
{
	Call_StartForward(g_fward_onBecome);
	Call_PushCell(client);
	Call_Finish();
}

public void Forward_OnCommanderLeft(int client)
{
	Call_StartForward(g_fward_onLeft);
	Call_PushCell(client);
	Call_Finish();
}

public Action Forward_OnCommanderCreationPre(int client)
{
	Action result;
	result = Plugin_Continue;
	
	Call_StartForward(g_fward_onBecomePre);
	Call_PushCell(client);
	Call_Finish(result);
	
	return result;
}