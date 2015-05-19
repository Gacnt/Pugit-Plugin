#include <sourcemod>
#include <sdktools>
#include <cstrike>

stock bool IsValidClient(int client) {
   // Check to see if a valid player.
   return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}

stock bool InWarmup() {
   // Check to see if game is currently in warmup.
   return GameRules_GetProp("m_bWarmupPeriod") != 0;
}

stock bool IsPlayer(int client) {
   // Check to see if a real boy.
   return IsValidClient(client) && !IsFakeClient(client);
}

stock void SwitchClientTeam(int client, int team) {
   // Check to see if they're trying to switch to the same team.
   if (GetClientTeam(client) == team)
      return;

   // If not trying to move to spectators team, move them to team they want to be on.
   if (team > CS_TEAM_SPECTATOR) {
      CS_SwitchTeam(client, team);
      CS_UpdateClientModel(client);
      CS_RespawnPlayer(client);
   }
}

stock void CheckAndRemoveStats(int client) {
   // Check and reset stats for client;
   g_PlayerKills[client] = 0;
   g_PlayerDeaths[client] = 0;
   g_PlayerAssists[client] = 0;
   g_Player2k[client] = 0;
   g_Player3k[client] = 0;
   g_Player4k[client] = 0;
   g_PlayerAce[client] = 0;
   g_PlayerHS[client] = 0;
   g_PlayerBombplant[client] = 0;
   g_PlayerDefuse[client] = 0;
}

stock void CheckAndRemoveCaptain(int client) {
   // Check and remove captain flag and decrease amnt of team captains.
   if (g_TeamCaptain[client]) {
      g_TeamCaptain[client] = false;
      g_AmntTeamCaptains -= 1;
      CS_SetMVPCount(client, 0);
      PrintToChat(client, "[PUGIT] You are no longer team captain");
   }
}

stock void CheckAndRemoveReady(int client) {
   // Remove ready and decrease ready count of players.
   if (g_PlayerReady[client]) {
      g_PlayerReady[client] = false;
      g_PlayersReady -= 1;
      CS_SetClientClanTag(client, "[NOT READY]");
      PrintToChat(client, "[PUGIT] You are no longer ready.");
   }
}

stock void SwapAllTeams(int client) {
   // Swap all players teams.
   if (g_TeamCaptainWon[client] && g_KnifeRound && g_KnifeRoundWon) {
      for (int i = 1; i <= MaxClients; i++) {
         if (IsPlayer(i)) {
            switch (GetClientTeam(i)) {
               // If they are a CT, swap them to T
               case CS_TEAM_CT: {
                  SwitchClientTeam(i, CS_TEAM_T);
               }
               case CS_TEAM_T: {
                  // If they are a T, swap them to CT
                  SwitchClientTeam(i, CS_TEAM_CT);
               }
            }
         }
      }
   } else {
      PrintToChat(client, "[PUGIT] Sorry your team did not win the knife round.");
   }
}

stock void KeepTeams(int client) {
   // Team Captain decided to keep teams, begin the match.
   if (g_TeamCaptainWon[client] && g_KnifeRound && g_KnifeRoundWon) {
      PrintToChatAll("[PUGIT] Starting Game");
      StartMatch();
   } else {
      PrintToChat(client, "[PUGIT] Sorry your team did not win the knife round.");
   }
}

stock void StartMatch() {
  g_KnifeRound = false;
  ServerCommand("exec live.cfg");
  CreateTimer(5.1, Restart2);
  RestartGame(1);
}

public Action Restart2(Handle timer) {
  CreateTimer(7.1, Restart3);
  RestartGame(1);
  return Plugin_Handled;
}

public Action Restart3(Handle timer) {
  RestartGame(1);
  PrintToChatAll("[PUGIT] --- GAME LIVE ---");
  PrintToChatAll("[PUGIT] --- GAME LIVE ---");
  PrintToChatAll("[PUGIT] --- GAME LIVE ---");
  PrintToChatAll("[PUGIT] ----- GL&HF -----");
  return Plugin_Handled;
}

stock void StartKnifeRound() {
  ConnectToDB();
  g_GameLive = true;
  g_KnifeRound = true;
  ServerCommand("exec knife.cfg");
  EndWarmup();
  RestartGame(1);
}

stock void StartWarmup() {
  ServerCommand("bot_quota 0");
  ServerCommand("bot_join_after_player 0");
  ServerCommand("exec live.cfg");
  ServerCommand("mp_do_warmup_period 1");
  ServerCommand("mp_warmuptime 60");
  ServerCommand("mp_warmup_start");
  ServerCommand("mp_warmup_pausetimer 1");
}

stock void EndWarmup() {
  ServerCommand("mp_warmup_end");
}

stock bool ReadyPlayer(int client) {
   // Ready the player up
   if (IsPlayer(client)) {
      if (!g_PlayerReady[client]) {
         if (!g_TeamCaptain[client]) {
            // If not a team captain, set their clan tag to READY.
            CS_SetClientClanTag(client, "[READY]");
         }
         g_PlayerReady[client] = true;
         g_PlayersReady += 1;
         PrintToChat(client, "[PUGIT] You are now ready.");
         if (g_PlayersReady == g_ConVarMaxPlayersReady && g_AmntTeamCaptains < g_ConVarMaxTeamCaptains) {
            // If all players are ready and no team captains have been decided, wait on team captain decision before starting game.
            g_WaitingForCaptains = true;
            PrintToChatAll("[PUGIT] All players are ready. When captains are chosen the game will start. [!captain]");
         }
         if (g_PlayersReady == g_ConVarMaxPlayersReady && g_AmntTeamCaptains == g_ConVarMaxTeamCaptains) {
          PrintToChatAll("[PUGIT] Starting Knife Round");
          StartKnifeRound();
         }
         return true;
      } else {
         PrintToChat(client, "[PUGIT] You are already ready.");
         return false;
      }
   } else {
      PrintToChat(client, "[PUGIT] You are not a real boy.");
      return false;
   }
}

stock bool SetTeamCaptain(int client) {
   // Set team captain when player wants to be a team captain

   if (IsPlayer(client)) {
      // Make sure there are not already 2 captains.
      if (g_AmntTeamCaptains < g_ConVarMaxTeamCaptains) {
         if (!g_TeamCaptain[client]) {
            // Make sure players team doesn't already have a team captain.
            for (int i = 1; i <= MaxClients; i++) {
              if (g_TeamCaptain[i]) {
                if (GetClientTeam(i) == GetClientTeam(client)) {
                  PrintToChat(client, "[PUGIT] Sorry your team already has a captain.");
                  return false;
                }
              }
            }
            CS_SetMVPCount(client, 1);
            CS_SetClientClanTag(client, "[CAPTAIN]");
            g_AmntTeamCaptains += 1;
            g_TeamCaptain[client] = true;
            PrintToChat(client, "[PUGIT] You are now the team captain.");
            // If they are waiting for captains, and captain amount is met, start game.
            if (g_WaitingForCaptains) {
               if (g_AmntTeamCaptains == g_ConVarMaxTeamCaptains) {
                  StartKnifeRound();
                  PrintToChatAll("[PUGIT] Starting Knife Round.");
                  return true;
               }
            }
            // If player is not ready, set them as ready.
            if (!g_PlayerReady[client]) {
               ReadyPlayer(client);
            }
            return true;
         } else {
            PrintToChat(client, "[PUGIT] You are already the team captain.");
            return false;
         }
      } else {
         PrintToChat(client, "[PUGIT] Sorry both team captain positions are full.");
         return false;
      }
   } else {
      PrintToChat(client, "[PUGIT] Sorry you are not a real boy.");
      return false;
   }
}

stock void DecidePlayerKills(int client) {
  if (g_PlayerKills[client] >= 2) {
    g_Player2k[client] = 1;
  }
  if (g_PlayerKills[client] >= 3) {
    g_Player3k[client] = 1;
  }
  if (g_PlayerKills[client] >= 4) {
    g_Player4k[client] = 1;
  }
  if (g_PlayerKills[client] >= 5) {
    g_PlayerAce[client] = 1;
  }
}

stock bool SetTeamCaptainWon(int team) {
  for (int i = 1; i <= MaxClients; i++) {
    if (g_TeamCaptain[i]) {
      if (GetClientTeam(i) == team) {
        g_TeamCaptainWon[i] = true;
        PrintToChat(i, "[PUGIT] Your team wins the knife round! Type !stay till satisfed, then !keep to begin the match!");
        return true;
      }
    }
  }
  return false;
}

stock void AnnounceWinningTeam(int team) {
  switch (team) {
    case (CS_TEAM_CT): {
      PrintToChatAll("[PUGIT] Counter-Terrorists win the knife round!!");
    }
    case (CS_TEAM_T): {
      PrintToChatAll("[PUGIT] Terrorists win the knife round!!");
    }
  }
}

stock bool IsTvEnabled() {
   // Check to see if GOTV is enabled.
   Handle  tvEnabledCvar = FindConVar("tv_enabled");
   if (tvEnabledCvar == INVALID_HANDLE) {
      LogError("Failed to get TV Cvar");
      return false;
   }

   return GetConVarInt(tvEnabledCvar) != 0;
}

stock bool Record(const char[] demoName) {
   // Start recording of match.
   char szDemoName[256];
   strcopy(szDemoName, sizeof(szDemoName), demoName);
   ServerCommand("tv_record \"%s\"", szDemoName);

   if (!IsTvEnabled()) {
      LogError("Autorecording will not work until tv_enable = 1");
      return false;
   }

   return true;

}

stock void StopRecording() {
   // Self explanitory function
   ServerCommand("tv_stoprecord");
}

stock void RestartGame(int delay) {
   // Easy Restart
   ServerCommand("mp_restartgame %d", delay);
}

