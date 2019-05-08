#include <sourcemod>
#include <ripext>

#pragma semicolon 1
#pragma newdecls required

static char g_sURL[] = "https://api.gamssi.com";
HTTPClient httpClient;

bool g_bIsMember[MAXPLAYERS + 1];

Handle fw_OnGroupCheck = null;

public Plugin myinfo =
{
    name = "[SM] GroupCheck",
    author = "B3none",
    description = "Steam groupcheck plugin.",
    version = "1.0.0",
    url = "https://github.com/b3none"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_groupcheck", GroupCheck);
	
	httpClient = new HTTPClient(g_sURL);
	
	fw_OnGroupCheck = CreateGlobalForward("GroupCheck_OnGroupCheck", ET_Ignore, Param_Cell, Param_Cell);
}

public Action GroupCheck(int client, any args)
{
	if (g_bIsMember[client]) 
	{
		return;
	}

	GetGroupStatus(client);
}

public void GetGroupStatus(int client)
{
	char sAuth64[64];
	GetClientAuthId(client, AuthId_SteamID64, sAuth64, sizeof(sAuth64));

	char Endpoint[128];
	Format(Endpoint, sizeof(Endpoint), "/v1/group-checker/%s", sAuth64);

	httpClient.Get(Endpoint, OnGroupCheckRecieved, client);
}

public void OnGroupCheckRecieved(HTTPResponse response, int client)
{
    if (response.Status != HTTPStatus_OK)
    {
        // The endpoint did not return a 200
        LogError("[SM] The Groupcheck web enpoint did not return a 200");
        PrintToConsole(client, "[SM] The Groupcheck web enpoint did not return a 200");
        
        return;
    }
    
    if (response.Data == null) 
    {
        // Invalid JSON response
        LogError("[SM] The Groupcheck web enpoint did not return valid JSON");
        PrintToConsole(client, "[SM] The Groupcheck web enpoint did not return valid JSON");
        
        return;
    }

    // Indicate that the response is a JSON object
    JSONObject data = view_as<JSONObject>(response.Data);

    bool b_IsMember = data.GetBool("grantAccess");
    g_bIsMember[client] = b_IsMember;
    
    OnGroupCheck(client, b_IsMember);
}

void OnGroupCheck(int client, bool IsMember)
{
	Call_StartForward(fw_OnGroupCheck);
	
	Call_PushCell(client);
	Call_PushCell(IsMember);
	
	Call_Finish();
}
