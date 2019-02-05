#include <sourcemod>
#include <SteamWorks>

#pragma semicolon 1
#pragma newdecls required

static char g_sURL[] = "https://api.gamssi.com";
bool g_bIsMember[MAXPLAYERS + 1];

public Plugin myinfo = {
    name = "[SM] Groupcheck",
    author = "B3none",
    description = "Steam groupcheck plugin.",
    version = "1.0.0",
    url = "https://github.com/b3none"
};

public void OnPluginStart() 
{
    RegConsoleCmd("sm_check", Cmd_Check);
}

public Action Cmd_Check(int client, any args)
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

	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, requestUrl);
	if (request == INVALID_HANDLE) {
		LogError("[group checker] Failed to create HTTP POST request using url: %s", requestUrl);
		PrintToConsole(client, "failed to create request");
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
	char sUserId[64];
	pack.ReadString(sUserId, sizeof(sUserId));

	int client = GetClientOfUserId(StringToInt(sUserId));

	int len = 0;
	SteamWorks_GetHTTPResponseBodySize(request, len);
	char[] response = new char[len];
	SteamWorks_GetHTTPResponseBodyData(request, response, len);

	// Horrible hack because working with JSON in sourcepawn makes me want to gauge my eyes out.
	g_bIsMember[client] = StrContains(response, "grantAccess\":true") != -1;

	delete pack;
}
