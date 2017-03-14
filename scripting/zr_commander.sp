/*  ZR Commander
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <colorvariables>
#include <zombiereloaded>
#include <zrcommander>
#undef REQUIRE_PLUGIN
#include <voiceannounce_ex>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION   "a0.2"

int Commander = -1;
Handle g_fward_onBecome;
Handle g_fward_onBecomePre;
Handle g_fward_onLeft;
int g_points[MAXPLAYERS + 1];
new Handle:c_GameCredits = INVALID_HANDLE;

public Plugin myinfo = {
	name = "ZR Commander",
	author = "Franc1sco",
	description = "ZR commander script",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart() 
{
	
	c_GameCredits = RegClientCookie("zrpoints", "zrpoints", CookieAccess_Private);
	
	RegConsoleCmd("sm_c", BecomeCommander);
	RegConsoleCmd("sm_commander", BecomeCommander);
	RegConsoleCmd("sm_uc", ExitCommander);
	RegConsoleCmd("sm_uncommander", ExitCommander);
	
	RegAdminCmd("sm_rc", RemoveCommander, ADMFLAG_GENERIC);
	
	HookEvent("round_start", roundStart);
	HookEvent("player_death", playerDeath); 

	CreateConVar("zr_commander_version", PLUGIN_VERSION,  "Plugin version", FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
			if(AreClientCookiesCached(client))
			{
				OnClientCookiesCached(client);
			}
	}
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

#if defined _voiceannounceex_included_
public bool:OnClientSpeakingEx(client)
{
	if(Commander == client)
	{
		PrintHintTextToAll("The ZR commander %N are speaking", client);
	}
		
}
#endif

public Action:HookSay(id,args)
{
	if(Commander == id)
	{
		decl String:SayText[512];
		GetCmdArgString(SayText,sizeof(SayText));
	
		StripQuotes(SayText);
	
		if(SayText[0] == '@' || SayText[0] == '/' || SayText[0] == '!' || !SayText[0])
			return Plugin_Continue;
			
		CPrintToChatAll("{darkred}[COMMANDER]{green} %N:{darkred}", id, SayText);
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnClientCookiesCached(client)
{
	new String:CreditsString[12];
	GetClientCookie(client, c_GameCredits, CreditsString, sizeof(CreditsString));
	g_points[client]  = StringToInt(CreditsString);
}

public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{
	if(client == Commander && motherInfect)
	{
		new Handle:pack;
		CreateDataTimer(0.1, Pasado, pack);
		WritePackCell(pack, client);
		WritePackCell(pack, respawnOverride);
		WritePackCell(pack, respawn);
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Pasado(Handle:timer, Handle:pack)
{
	new client;
	new respawnOverride;
	new respawn;
	
	ResetPack(pack);
	client = ReadPackCell(pack);
	respawnOverride = ReadPackCell(pack);
	respawn = ReadPackCell(pack);
	if(!IsClientInGame(client)) return;
	new aleatorio = ObtenerClienteAleatorio(client);
	if(aleatorio) 
	{
		ZR_InfectClient(aleatorio, -1, true, bool:respawnOverride, bool:respawn);
	}
}

stock ObtenerClienteAleatorio(client)
{
	new clients[MaxClients+1], clientCount;
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i) && i != client && client != Commander)
		clients[clientCount++] = i;
	return (clientCount == 0) ? 0 : clients[GetRandomInt(0, clientCount-1)];
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
	
	if(AreClientCookiesCached(client))
	{
		new String:CreditsString[12];
		Format(CreditsString, sizeof(CreditsString), "%i", g_points[client]);
		SetClientCookie(client, c_GameCredits, CreditsString);
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