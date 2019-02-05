#include <sourcemod>
#include <SteamWorks>

#pragma semicolon 1
#pragma newdecls required

static char g_sURL[] = "https://api.gamssi.com";
bool g_bIsMember[MAXPLAYERS + 1];

Handle fw_OnGroupCheck = null;

public Plugin myinfo = {
    name = "[SM] GroupCheck",
    author = "B3none",
    description = "Steam groupcheck plugin.",
    version = "1.0.0",
    url = "https://github.com/b3none"
};

public void OnPluginStart() 
{
    RegConsoleCmd("sm_groupcheck", GroupCheck);
    
    fw_OnGroupCheck = CreateGlobalForward("GroupCheck_OnGroupCheck", ET_Ignore, Param_Cell, Param_Cell);
}

public Action GroupCheck(int client, any args)
{
	if(g_bIsMember[client]) 
	{
		return;
	}

	GetGroupStatus(client);
}

public void GetGroupStatus(int client)
{
	char sAuth64[64];
	GetClientAuthId(client, AuthId_SteamID64, sAuth64, sizeof(sAuth64));

	char sUserId[64];
	IntToString(GetClientUserId(client), sUserId, sizeof(sUserId));

	char requestUrl[128];
	Format(requestUrl, sizeof(requestUrl), "%s/v1/group-checker/%s", g_sURL, sAuth64);

	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, requestUrl);
	if (request == INVALID_HANDLE) 
	{
		LogError("[SM] Groupcheck failed to create HTTP GET request using url: %s", requestUrl);
		PrintToConsole(client, "[SM] Groupcheck failed to create HTTP GET request using url: %s", requestUrl);
		return;
	}

	DataPack pack = new DataPack();
	pack.WriteString(sUserId);

	SteamWorks_SetHTTPCallbacks(request, OnInfoReceived);
	SteamWorks_SetHTTPRequestContextValue(request, pack);
	SteamWorks_SendHTTPRequest(request);
}

public int OnInfoReceived(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, Handle data)
{
	DataPack pack = view_as<DataPack>(data);
	pack.Reset();
	char UserId[64];
	pack.ReadString(UserId, sizeof(UserId));

	int client = GetClientOfUserId(StringToInt(UserId));

	int length = 0;
	SteamWorks_GetHTTPResponseBodySize(request, length);
	char[] response = new char[length];
	SteamWorks_GetHTTPResponseBodyData(request, response, length);
	
	// Horrible hack because working with JSON in sourcepawn makes me want to gauge my eyes out.
	bool b_IsMember = StrContains(response, "grantAccess\":true") != -1;
	
	OnGroupCheck(client, b_IsMember);

	delete pack;
}

void OnGroupCheck(int client, bool IsMember)
{
	Call_StartForward(fw_OnGroupCheck);
	
	Call_PushCell(client);
	Call_PushCell(IsMember);
	
	Call_Finish();
}
