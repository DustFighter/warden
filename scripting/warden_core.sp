#include <sourcemod>
#include "include/warden_core.inc"

#pragma semicolon 1
#pragma newdecls required

enum Item
{
	String:Display[32],
	String:Info[32],
	Warden_MenuCategory:Category,
	Warden_MenuCallback:Callback,
	Handle:Owner,
};

const int kMaxItems = 32;

int g_warden = -1;
int g_menu_item[kMaxItems][Item];
int g_menu_item_count[Warden_MenuCategory];
int g_menu_item_count_total;
int g_color[3];

bool g_day;

Handle g_fwd_created = null;
Handle g_fwd_removed = null;

ConVar g_cvar_enable_menu = null;
ConVar g_cvar_render_color = null;

public Plugin myinfo =
{
	name = "Warden Core",
	author = "Godis",
	description = "A modular JailBreak plugin for SourceMod",
	version = kWardenVersion,
	url = "https://github.com/godisfarfar/warden"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Warden_RegisterItem", Native_RegisterItem);
	CreateNative("Warden_DeregisterItem", Native_DeregisterItem);
	CreateNative("Warden_FindItem", Native_FindItem);
	CreateNative("Warden_Set", Native_SetWarden);
	CreateNative("Warden_Get", Native_GetWarden);
	RegPluginLibrary("warden_core");
	return APLRes_Success;
}

public void OnPluginStart()
{
	EngineVersion game_engine = GetEngineVersion();
	if((game_engine != Engine_CSS) && (game_engine != Engine_CSGO) && (game_engine != Engine_TF2))
	{
		SetFailState("This game is not supported");
	}
	
	CreateConVar("sm_warden_core_version", kWardenVersion, "Warden Core version", FCVAR_DONTRECORD);
	g_cvar_enable_menu = CreateConVar("sm_warden_core_enable_menu", "1", "Enable the warden menu.");
	g_cvar_render_color = CreateConVar("sm_warden_core_render_color", "0,0,255", "RGB color code, modifies the wardens model color.");
	
	char buffer[32];
	g_cvar_render_color.GetString(buffer, sizeof(buffer));
	g_color = UpdateRenderColor(buffer);
	g_cvar_render_color.AddChangeHook(OnConVarChanged);
	
	g_fwd_created = CreateGlobalForward("OnWardenCreated", ET_Ignore, Param_Cell);
	g_fwd_removed = CreateGlobalForward("OnWardenRemoved", ET_Ignore, Param_Cell);
	
	RegConsoleCmd("sm_w", Cmd_Warden);
	RegConsoleCmd("sm_warden", Cmd_Warden);
	
	RegConsoleCmd("sm_uw", Cmd_UnWarden);
	RegConsoleCmd("sm_unwarden", Cmd_UnWarden);
	RegConsoleCmd("sm_retire", Cmd_UnWarden);
	RegConsoleCmd("sm_resign", Cmd_UnWarden);
	
	RegAdminCmd("sm_rw", Cmd_RemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_removewarden", Cmd_RemoveWarden, ADMFLAG_GENERIC);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	LoadTranslations("warden_core.phrases");
}

public void OnClientDisconnect(int client)
{
	if(g_warden == client)
	{
		char warden_name[MAX_NAME_LENGTH];
		GetClientName(client, warden_name, sizeof(warden_name));
		
		PrintCenterTextAll("%t", "WardenLeft", warden_name);
		
		StartForward(g_warden, g_fwd_removed);
		g_warden = -1;
	}
}

public void OnConVarChanged(ConVar cvar, const char[] old_value, const char[] new_value)
{
	g_color = UpdateRenderColor(new_value);
	
	if(g_warden != -1)
	{
		SetEntityRenderColor(g_warden, g_color[0], g_color[1], g_color[2], 255);
	}
}

public Action Cmd_Warden(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[warden_core.smx] This command can only be used in-game.");
		return Plugin_Handled;
	}
	
	if(g_warden == -1)
	{
		if(GetClientTeam(client) == 3)
		{
			if(IsPlayerAlive(client))
			{
				char warden_name[MAX_NAME_LENGTH];
				GetClientName(client, warden_name, sizeof(warden_name));
				
				g_warden = client;
				SetEntityRenderColor(client, g_color[0], g_color[1], g_color[2], 255);
				StartForward(client, g_fwd_created);
				
				PrintCenterTextAll("%t", "BecomeWarden3", warden_name);
				
				if((g_cvar_enable_menu.IntValue == 1) && (g_menu_item_count_total > 0))
				{
					PrintToChat(client, "[Warden] %t", "BecomeWarden1");
				}
				
				PrintToChat(client, "[Warden] %t", "BecomeWarden2");
				return Plugin_Handled;
			}
			else
			{
				PrintToChat(client, "[Warden] %t", "BecomeWarden_Denied1");
				return Plugin_Handled;
			}
		}
		else
		{
			PrintToChat(client, "[Warden] %t", "BecomeWarden_Denied2");
			return Plugin_Handled;
		}
	}
	else
	{
		if((g_warden == client) && (g_cvar_enable_menu.IntValue == 1))
		{
			Menu1(client);
			return Plugin_Handled;
		}
		else
		{
			char warden_name[MAX_NAME_LENGTH];
			GetClientName(g_warden, warden_name, sizeof(warden_name));
			
			PrintToChat(client, "[Warden] %t", "CurrentWarden", warden_name);
			return Plugin_Handled;
		}
	}
}

public Action Cmd_UnWarden(int client, int args)
{
	if(g_warden == client)
	{
		char warden_name[MAX_NAME_LENGTH];
		GetClientName(client, warden_name, sizeof(warden_name));
		
		StartForward(g_warden, g_fwd_removed);
		SetEntityRenderColor(g_warden, 255, 255, 255, 255);
		g_warden = -1;
		
		PrintCenterTextAll("%t", "ResignWarden1", warden_name);
		return Plugin_Handled;
	}
	else
	{
		PrintToChat(client, "[Warden] %t", "ResignWarden2");
		return Plugin_Handled;
	}
}

public Action Cmd_RemoveWarden(int client, int args)
{
	Perform_RemoveWarden(client);
	return Plugin_Handled;
}

public Action Event_RoundStart(Event event, const char[] command, bool dontBroadcast)
{
	if(g_warden != -1)
	{
		SetEntityRenderColor(g_warden, 255, 255, 255, 255);
		g_warden = -1;
	}
	
	if(g_day)
	{
		g_day = false;
	}
}

public Action Event_PlayerDeath(Event event, const char[] command, bool dontBroadcast)
{
	if(g_warden == GetClientOfUserId(event.GetInt("userid")))
	{
		char warden_name[MAX_NAME_LENGTH];
		GetClientName(g_warden, warden_name, sizeof(warden_name));
		
		StartForward(g_warden, g_fwd_removed);
		
		PrintCenterTextAll("%t", "WardenDead", warden_name);
		
		g_warden = -1;
	}
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		
		if(StrEqual(info, "days"))
		{
			Menu2(param1, Warden_MenuCategoryDays);
		}
		else if(StrEqual(info, "games"))
		{
			Menu2(param1, Warden_MenuCategoryGames);
		}
		else if(StrEqual(info, "other"))
		{
			Menu2(param1, Warden_MenuCategoryOther);
		}
		else
		{
			int item = StringToInt(info);
			if((g_menu_item[item][Category] == Warden_MenuCategoryDays))
			{
				if(g_day)
				{
					PrintToChat(param1, "[Warden] %t", "OngoingDay");
					return;
				}
				g_day = true;
			}
			
			Call_StartFunction(g_menu_item[item][Owner], view_as<Function>(g_menu_item[item][Callback]));
			Call_PushCell(param1);
			Call_PushString(g_menu_item[item][Info]);
			Call_Finish();
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			Menu1(param1);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

void Menu1(int client)
{
	Menu menu = new Menu(MenuHandler);
	menu.SetTitle("%t", "WardenMenuTitle");
	
	char buffer[32];
	if(g_menu_item_count[Warden_MenuCategoryDays] > 0)
	{
		Format(buffer, sizeof(buffer), "%t", "WardenMenuDays");
		menu.AddItem("days", buffer);
	}
	if(g_menu_item_count[Warden_MenuCategoryGames] > 0)
	{
		Format(buffer, sizeof(buffer), "%t", "WardenMenuGames");
		menu.AddItem("games", buffer);
	}
	if(g_menu_item_count[Warden_MenuCategoryOther] > 0)
	{
		Format(buffer, sizeof(buffer), "%t", "WardenMenuOther");
		menu.AddItem("other", buffer);
	}
	
	menu.ExitButton = true;
	menu.Display(client, 20);
}

void Menu2(int client, Warden_MenuCategory category)
{
	Menu menu = new Menu(MenuHandler);
	menu.SetTitle("%t", "WardenMenuTitle");
	
	for(int i = 0; i < kMaxItems; i++)
	{
		if((g_menu_item[i][Category] == category) && (g_menu_item[i][Owner] != null))
		{
			char buffer[32];
			IntToString(i, buffer, sizeof(buffer));
			
			menu.AddItem(buffer, g_menu_item[i][Display]);
		}
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, 20);
}

void Perform_RemoveWarden(int client)
{
	char warden_name[MAX_NAME_LENGTH];
	GetClientName(g_warden, warden_name, sizeof(warden_name));
	
	StartForward(g_warden, g_fwd_removed);
	
	PrintCenterTextAll("%t", "RemoveWarden1", warden_name);
	
	ShowActivity2(client, "[Warden] ", "%t", "RemoveWarden2", warden_name);
	LogAction(client, g_warden, "\"%L\" removed current warden \"%L\"", client, g_warden);
	
	SetEntityRenderColor(g_warden, 255, 255, 255, 255);
	g_warden = -1;
}

public int Native_RegisterItem(Handle plugin, int params)
{
	char info[32];
	GetNativeString(1, info, sizeof(info));
	
	char display[32];
	GetNativeString(2, display, sizeof(display));
	
	int item = -1;
	
	for (int i = 0; i < kMaxItems; i++)
	{
		if(g_menu_item[i][Owner] == null)
		{
			Format(g_menu_item[i][Info], 32, info);
			Format(g_menu_item[i][Display], 32, display);
			g_menu_item[i][Category] = view_as<Warden_MenuCategory>(GetNativeCell(3));
			g_menu_item[i][Callback] = GetNativeCell(4);
			g_menu_item[i][Owner] = plugin;
			
			g_menu_item_count[ g_menu_item[i][Category] ]++;
			g_menu_item_count_total++;
			
			item = i;
			
			break;
		}
	}
	
	return item;
}

public int Native_DeregisterItem(Handle plugin, int params)
{
	int item = GetNativeCell(1);
	
	if((item >= 0) && (item < kMaxItems) && (g_menu_item[item][Owner] != null))
	{
		g_menu_item_count_total--;
		g_menu_item_count[ g_menu_item[item][Category] ]--;
		g_menu_item[item][Owner] = null;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item with id \"%i\" does not exist!", item);
	}
}

public int Native_FindItem(Handle plugin, int params)
{
	char display[32];
	GetNativeString(1, display, sizeof(display));
	
	Warden_MenuCategory category;
	category = view_as<Warden_MenuCategory>(GetNativeCell(2));
	
	for(int i = 0; i < kMaxItems; i++)
	{
		if(StrEqual(g_menu_item[i][Display], display) && (g_menu_item[i][Category] == category))
		{
			return i;
		}
	}
	
	return -1;
}

public int Native_SetWarden(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if((client < 1) || (client > MaxClients) || !IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %i is invalid.", client);
	}
	
	StartForward(g_warden, g_fwd_removed);
	SetEntityRenderColor(g_warden, 255, 255, 255, 255);
	
	g_warden = client;
	
	StartForward(client, g_fwd_created);
	SetEntityRenderColor(client, g_color[0], g_color[1], g_color[2], 255);
}

public int Native_GetWarden(Handle plugin, int params)
{
	return g_warden;
}

int[] UpdateRenderColor(const char[] str)
{
	char section[3][4];
	ExplodeString(str, ",", section, sizeof(section), sizeof(section[]));
	
	int rgb[3];
	for(int i = 0; i < sizeof(rgb); i++)
	{
		TrimString(section[i]);
		rgb[i] = StringToInt(section[i]);
	}
	
	return rgb;
}

void StartForward(int client, Handle fwd)
{
	Call_StartForward(fwd);
	Call_PushCell(client);
	Call_Finish();
}
