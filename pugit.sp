new g_PlayerReady[MAXPLAYERS+1];
new g_PlayerKills[MAXPLAYERS+1];
new g_PlayerDeaths[MAXPLAYERS+1];
new g_PlayerAssists[MAXPLAYERS+1];
new g_Player2k[MAXPLAYERS+1];
new g_Player3k[MAXPLAYERS+1];
new g_Player4k[MAXPLAYERS+1];
new g_PlayerAce[MAXPLAYERS+1];
new g_PlayerHS[MAXPLAYERS+1];
new g_PlayerBombplant[MAXPLAYERS+1];
new g_PlayerDefuse[MAXPLAYERS+1];
new g_TeamCaptain[MAXPLAYERS+1];
new g_TeamCaptainWon[MAXPLAYERS+1];
new g_AmntTeamCaptains = 0;
new g_PlayersReady = 0;
new g_WaitingForCaptains = false;
new g_GameLive = false;
new g_KnifeRound = false;
new g_KnifeRoundWon = false;
new g_ConVarMaxPlayersReady = 2;
new g_ConVarMaxTeamCaptains = 2;
new g_MatchID;

#include "pugit/generic.sp"
#include "pugit/dbinteract.sp"
#include <sourcemod>
#include <cstrike>
#include <sdktools>

public Plugin:myinfo = {
   name = "PUGIT Scrims",
   author = "Panic",
   description = "PUGIT Scrim Manager",
   version = "1.0",
   url = "http://www.pugit.net/"
}

public OnPluginStart() {
   RegConsoleCmd("ready", Event_PlayerReady, "Ready Up Player.");
   RegConsoleCmd("switch", Event_SwitchTeams, "Lets Captains Switch Teams.");
   RegConsoleCmd("keep", Event_KeepTeams, "Lets Captains Keep Teams.");
   RegConsoleCmd("captain", Event_SetCaptain, "Lets Player Choose To Be Captain.");
   RegConsoleCmd("donate", Event_ShowDonateMOTD, "Shows the players the donate page");
   CreateTimer(30.0, Event_RemindReadyPlayer, _, TIMER_REPEAT);
   CreateTimer(60.0, Event_ThanksForPlaying, _, TIMER_REPEAT);
   AddCommandListener(Event_PlayerTeam, "jointeam");
   HookEvent("round_end", Event_RoundEnded);
   HookEvent("player_death", Event_PlayerDied);
   HookEvent("bomb_planted", Event_Bombplanted);
   HookEvent("bomb_defused", Event_Bombdefused);
}

public void OnClientDisconnect(int client) {
  CheckAndRemoveStats(client);
  CheckAndRemoveCaptain(client);
  CheckAndRemoveReady(client);
}

public void OnMapStart() {
  StartWarmup();
}

public void OnClientPutInServer(int client) {
  if (IsFakeClient(client)) {
    KickClient(client);
    ServerCommand("bot_quota 0");
  }
}

public Action Event_RemindReadyPlayer(Handle timer) {
  if (!g_GameLive) {
    for (int i = 1; i <= MaxClients; i++) {
      if (!g_PlayerReady[i] && IsPlayer(i)) {
        PrintToChat(i, "[PUGIT] You are not ready. Type !ready to ready up.");
      }
    }
  }
}

public Action Event_ThanksForPlaying(Handle timer) {
  if (!g_GameLive)
    PrintToChatAll("[PUGIT] Thank you for playing on Pugit.net. If you enjoy this service feel free to donate. (!donate)");
}

public Action Event_RoundEnded(Event event, char[] name, bool dontBroadcast) {
  if (!g_KnifeRoundWon && g_KnifeRound) {
    g_KnifeRoundWon = true;
    int team = GetEventInt(event, "winner");
    SetTeamCaptainWon(team);
    AnnounceWinningTeam(team);
  }

  if (g_GameLive && !g_KnifeRound) {
    UpdatePlayerStats();
  } 
}

public Action Event_PlayerDied(Event event, char[] name, bool dontBroadcast) {
  if (g_GameLive && !g_KnifeRound) {
    int PlayerDied = GetClientOfUserId(GetEventInt(event, "userid"));
    int PlayerKill = GetClientOfUserId(GetEventInt(event, "attacker"));
    int PlayerAssist = GetClientOfUserId(GetEventInt(event, "assister"));
   
    if (GetEventBool(event, "headshot")) {
      g_PlayerHS[PlayerKill] += 1;
    }
    g_PlayerKills[PlayerKill] += 1;
    g_PlayerDeaths[PlayerDied] += 1;
    g_PlayerAssists[PlayerAssist] += 1;
  }
  return Plugin_Handled;
}

public Action Event_Bombplanted(Event event, char[] name, bool dontBroadcast) {
  if (g_GameLive && !g_KnifeRound) {
    int PlanterID = GetClientOfUserId(GetEventInt(event, "userid"));
    g_PlayerBombplant[PlanterID] += 1;
  }
  return Plugin_Handled;
}

public Action Event_Bombdefused(Event event, char[] name, bool dontBroadcast) {
  if (g_GameLive && !g_KnifeRound) {
    int DefuserID = GetClientOfUserId(GetEventInt(event, "userid"));
    g_PlayerDefuse[DefuserID] += 1;
  }
  return Plugin_Handled;
}

public Action Event_PlayerReady(int client, int args) {
   ReadyPlayer(client);
   return Plugin_Handled;
}

public Action Event_SetCaptain(int client, int args) {
   SetTeamCaptain(client);
   return Plugin_Handled;
}

public Action Event_SwitchTeams(int client, int args) {
   SwapAllTeams(client);
   return Plugin_Handled;
}

public Action Event_KeepTeams(int client, int args) {
   KeepTeams(client);
   return Plugin_Handled;
}

public Action Event_PlayerTeam(int client, char[] command, int argc) {
  if (g_GameLive) {
    return Plugin_Handled;
  }
  SwitchClientTeam(client, argc);
  CheckAndRemoveCaptain(client);
  CheckAndRemoveReady(client);
  return Plugin_Continue;
}

public Action Event_ShowDonateMOTD(int client, int args) {
  PrintToChat(client, "[PUGIT] Thank you for your interest in donating.");
  ShowMOTDPanel(client, "Donate", "http://www.pugit.net/donate", MOTDPANEL_TYPE_URL);
  return Plugin_Handled;
}
