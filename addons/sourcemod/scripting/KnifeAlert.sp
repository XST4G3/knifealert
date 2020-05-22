////////////////////////////////////////////////////////////////////////////
//*****************************Обновление 1.2*****************************//
//1. Добавлены куки
//2. Добавлено меню управления
//3. Добавлен файл перевода
//4. Добавлен конфиг
//5. Оптимизация кода
////////////////////////////////////////////////////////////////////////////

#include <csgo_colors>
#include <sdktools>
#include <clientprefs>

Handle g_CvarSoundVolume, g_CvarChatAlert, g_CvarSoundAlert, g_hCookie;
float g_fSndVolume;
int g_iAlertChat, g_iSoundAlert[MAXPLAYERS+1], g_iSoundServer;

static const char g_SoundName[][] =
{
	"newpack/1.mp3",
	"newpack/2.mp3",
	"newpack/3.mp3",
	"newpack/4.mp3",
	"newpack/5.mp3",
	"newpack/6.mp3",
	"newpack/7.mp3",
	"newpack/8.mp3",
	"newpack/9.mp3"
};

public Plugin myinfo =
{
	name = "[CS:GO] KnifeAlert",
	author = "xstage",
	version = "1.2",
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_ka", KaRegConsole);
	HookEvent("player_death", Ev_PlayerDeath);
	
	g_CvarChatAlert = CreateConVar("sm_knife_alert", "1", "Оповещение в чате", _, true, 0.0, true, 1.0);
	HookConVarChange(g_CvarChatAlert, ChatAlertChange);
	g_iAlertChat = GetConVarInt(g_CvarChatAlert);

	g_CvarSoundAlert = CreateConVar("sm_knife_sound", "1", "Звуковые оповещения", _, true, 0.0, true, 1.0);
	HookConVarChange(g_CvarSoundAlert, SoundAlertChange);
	g_iSoundServer = GetConVarInt(g_CvarSoundAlert);
	
	g_CvarSoundVolume = CreateConVar("sm_knife_volume", "0.5", "Громкость звука", _, true, 0.1, true, 1.0);
	HookConVarChange(g_CvarSoundVolume, VolumeAlertChange);
	g_fSndVolume = GetConVarFloat(g_CvarSoundVolume);
	
	g_hCookie = RegClientCookie("g_iSoundAlert", "g_iSoundAlert", CookieAccess_Public);
	AutoExecConfig(true, "knifealert");
	LoadTranslations("knifealert.phrases");
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];		
	for (int i; i < sizeof(g_SoundName); ++i)
	{
		PrecacheSound(g_SoundName[i], true);
		Format(buffer, sizeof(buffer), "sound/%s", g_SoundName[i]);
		AddFileToDownloadsTable(buffer);
	}
}

public void OnClientCookiesCached(int iClient)
{
	char szValue[4];
	GetClientCookie(iClient, g_hCookie, szValue, sizeof(szValue));
	if(szValue[0]) g_iSoundAlert[iClient] = view_as<bool>(StringToInt(szValue));
	else g_iSoundAlert[iClient] = 1;
}

public Action KaRegConsole(int iClient, int iArgs)
{
	if(iArgs < 1 && iClient) KaCreateMenu(iClient);
	return Plugin_Handled;
}

public void KaCreateMenu(int iClient)
{
	Menu hMenu = new Menu(GetMenuKa);
	hMenu.SetTitle("KnifeAlert | Настройка клиента\n ");

	if(g_iSoundAlert[iClient]) hMenu.AddItem("", "Звук | Статус - Вкл");
	else hMenu.AddItem("", "Звук | Статус - Выкл\n");

	hMenu.Display(iClient, MENU_TIME_FOREVER);

	hMenu.ExitBackButton = false;
}

public int GetMenuKa(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{	
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			if(g_iSoundAlert[iClient]) //Игрок выключает звуковые оповещения
			{
				g_iSoundAlert[iClient] = 0;
				SetClientCookie(iClient, g_hCookie, "0");
				CGOPrintToChat(iClient, "%t", "AlertOff_Check");
			}
			else //Игрок включает звуковые оповещения
			{
				g_iSoundAlert[iClient] = 1;
				SetClientCookie(iClient, g_hCookie, "1");
				CGOPrintToChat(iClient, "%t", "AlertOn_Check");
			}
			KaCreateMenu(iClient);
		}
	}

}

public Action Ev_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	char weaponName[24];
	GetEventString(event, "weapon", weaponName, 24);

	if(StrContains(weaponName, "knife", false) != -1 || (StrContains(weaponName, "bayonet", false) != -1))
	{
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		int killer = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(g_iAlertChat) CGOPrintToChatAll("%t", "Alert_Chat", killer, victim);
		for(int i; i < MaxClients; i++)
		{
			if(i != 0)
			{
				if(IsClientInGame(i))
				{
					if(g_iSoundAlert[i] && g_iSoundServer) EmitSoundToClient(i, g_SoundName[GetRandomInt(0, sizeof(g_SoundName) - 1)], _, _, _, _, g_fSndVolume);
				}
			}
		}
	}
	return Plugin_Continue;
}
public void SoundAlertChange(Handle convar, char[] oldValue, char[] newValue) { g_iSoundServer = StringToInt(newValue); }
public void ChatAlertChange(Handle convar, char[] oldValue, char[] newValue) { g_iAlertChat = StringToInt(newValue); }
public void VolumeAlertChange(Handle convar, char[] oldValue, char[] newValue) { g_fSndVolume = StringToFloat(newValue); }