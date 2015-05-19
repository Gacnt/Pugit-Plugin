// Database Interactions

Handle PugitDatabase = INVALID_HANDLE;

stock void ConnectToDB() {
  SQL_TConnect(GotDatabase, "csgofreeservers", _);
}

public void GotDatabase(Handle owner, Handle hndl, char[] error, any data) {
  if (hndl == INVALID_HANDLE) {
    LogError("Failed to connect to database: %s", error);
  } else {
    // Got connection set Handle 
    PugitDatabase = hndl;

    // Insert match into Database.
    g_MatchID = GetCommandLineParamInt("-match_id", 0);
    InsertPlayersToTable();
  }
}

public void ErrorHandler(Handle owner, Handle hndl, char[] error, any data) {
  if (hndl == INVALID_HANDLE) {
    LogError("Error: %s", error);
  }
}

stock void InsertPlayersToTable() {
  for (int i = 1; i <= MaxClients; i++) {
    if (IsPlayer(i) && g_PlayerReady[i]) {
      char Query1[255];
      char Query2[255];
      char Name[255];
      char SteamID[255];
      GetClientAuthId(i, AuthId_SteamID64, SteamID, sizeof(SteamID), false);
      GetClientName(i, Name, sizeof(Name))
      Format(Query1, sizeof(Query1), "INSERT INTO `match_players` (match_id, player_name, player_steam_id) VALUES ('%d', '%s', '%s')", g_MatchID, Name, SteamID);
      Format(Query2, sizeof(Query2), "INSERT INTO `match` (match_id, steam_id) VALUES ('%d', '%s')", g_MatchID, SteamID);
      SQL_TQuery(PugitDatabase, ErrorHandler, Query1);
      SQL_TQuery(PugitDatabase, ErrorHandler, Query2);
    }
  }
}

stock void UpdatePlayerStats() {
  for (int i = 1; i <= MaxClients; i++) {
    if (IsPlayer(i) && g_PlayerReady[i]) {
      DecidePlayerKills(i);
      char Query1[5000];
      char SteamID[255];
      GetClientAuthId(i, AuthId_SteamID64, SteamID, sizeof(SteamID), false);
      Format(Query1, sizeof(Query1), "UPDATE `match_players` SET `player_kills` = `player_kills` + %d, `player_deaths` = `player_deaths` + %d, `player_assists` = `player_assists` + %d, `player_2k` = `player_2k` + %d, `player_3k` = `player_3k` + %d, `player_4k` = `player_4k` + %d, `player_ace` = `player_ace` + %d, `player_hs` = `player_hs` + %d, `player_bombplant` = `player_bombplant` + %d, `player_defuses` = `player_defuses` + %d WHERE `player_steam_id` = %s", g_PlayerKills[i], g_PlayerDeaths[i], g_PlayerAssists[i], g_Player2k[i], g_Player3k[i], g_Player4k[i], g_PlayerAce[i], g_PlayerHS[i], g_PlayerBombplant[i], g_PlayerDefuse[i], SteamID);
      SQL_TQuery(PugitDatabase, ErrorHandler, Query1);
      CheckAndRemoveStats(i);
    }
  }
}
