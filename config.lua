Config = {}

-- API-Endpunkt deines externen Status-Systems.
Config.ApiUrl = "https://example.com/fivem/status"

-- Muss mit dem API-Secret deiner externen Anwendung übereinstimmen.
Config.Secret = "CHANGE_ME"

-- Intervall in Sekunden, in dem Statusdaten gesendet werden.
Config.SendIntervalSeconds = 10

-- Standardwerte für die Anzeige, falls keine Server-Convars gesetzt sind.
Config.ServerName = "FiveM Server"
Config.Description = "Live Serverstatus"
Config.ConnectCommand = "connect 127.0.0.1:30120"

-- Fallback, falls sv_maxclients nicht gelesen werden kann.
Config.FallbackMaxPlayers = 10

-- Restart-Zeiten im Format HH:MM.
Config.RestartTimes = {
    "01:00",
    "08:00",
}

-- Debug-Ausgaben in der Serverkonsole.
Config.Debug = false
