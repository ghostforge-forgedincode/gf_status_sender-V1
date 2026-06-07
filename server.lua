local resourceName = GetCurrentResourceName()
local shutdownAlreadySent = false

local function debugPrint(message)
    if Config.Debug then
        print("^3[" .. resourceName .. "]^7 " .. tostring(message))
    end
end

local function safeCall(label, fn, fallback)
    local ok, result = pcall(fn)

    if not ok then
        debugPrint("FEHLER bei " .. tostring(label) .. ": " .. tostring(result))
        return fallback
    end

    if result == nil then
        return fallback
    end

    return result
end

local function getPlayerCount()
    return safeCall("getPlayerCount", function()
        return #GetPlayers()
    end, 0)
end

local function getMaxPlayers()
    return safeCall("getMaxPlayers", function()
        local maxPlayers = GetConvarInt("sv_maxclients", Config.FallbackMaxPlayers or 10)

        if not maxPlayers or maxPlayers <= 0 then
            return Config.FallbackMaxPlayers or 10
        end

        return maxPlayers
    end, Config.FallbackMaxPlayers or 10)
end

local function formatDuration(seconds)
    seconds = tonumber(seconds) or 0

    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400

    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600

    local minutes = math.floor(seconds / 60)

    if days > 0 then
        return string.format("%d Tage, %d Stunden, %d Minuten", days, hours, minutes)
    end

    if hours > 0 then
        return string.format("%d Stunden, %d Minuten", hours, minutes)
    end

    return string.format("%d Minuten", minutes)
end

local function getServerRuntime()
    return safeCall("getServerRuntime", function()
        local timer = GetGameTimer()

        if not timer or timer <= 0 then
            return "Unbekannt"
        end

        local seconds = math.floor(timer / 1000)
        return formatDuration(seconds)
    end, "Unbekannt")
end

local function parseTimeString(value)
    local hour, minute = string.match(tostring(value), "^(%d%d?):(%d%d)$")

    if not hour or not minute then
        return nil, nil
    end

    hour = tonumber(hour)
    minute = tonumber(minute)

    if not hour or not minute then
        return nil, nil
    end

    if hour < 0 or hour > 23 or minute < 0 or minute > 59 then
        return nil, nil
    end

    return hour, minute
end

local function getNextRestartText()
    return safeCall("getNextRestartText", function()
        local restartTimes = Config.RestartTimes or {}

        if #restartTimes <= 0 then
            return "Nicht gesetzt"
        end

        local now = os.time()
        local date = os.date("*t", now)
        local nearestDiff = nil

        for _, timeString in ipairs(restartTimes) do
            local hour, minute = parseTimeString(timeString)

            if hour and minute then
                local candidate = os.time({
                    year = date.year,
                    month = date.month,
                    day = date.day,
                    hour = hour,
                    min = minute,
                    sec = 0
                })

                if candidate <= now then
                    candidate = candidate + 86400
                end

                local diff = candidate - now

                if not nearestDiff or diff < nearestDiff then
                    nearestDiff = diff
                end
            end
        end

        if not nearestDiff then
            return "Nicht gesetzt"
        end

        return "in " .. formatDuration(nearestDiff)
    end, "Nicht gesetzt")
end

local function getResourceStats()
    return safeCall("getResourceStats", function()
        local total = GetNumResources()
        local started = 0

        for i = 0, total - 1 do
            local name = GetResourceByFindIndex(i)

            if name then
                local state = GetResourceState(name)

                if state == "started" then
                    started = started + 1
                end
            end
        end

        return {
            started = started,
            total = total
        }
    end, {
        started = 0,
        total = 0
    })
end

local function getServerBuild()
    return safeCall("getServerBuild", function()
        local build = GetConvar("sv_enforceGameBuild", "")

        if build and build ~= "" and build ~= "0" then
            return tostring(build)
        end

        local version = GetConvar("version", "")

        if version and version ~= "" then
            return tostring(version)
        end

        return "Nicht gesetzt"
    end, "Unbekannt")
end

local function getServerName()
    return safeCall("getServerName", function()
        local projectName = GetConvar("sv_projectName", "")

        if projectName and projectName ~= "" then
            return projectName
        end

        local hostname = GetConvar("sv_hostname", "")

        if hostname and hostname ~= "" then
            return hostname
        end

        return Config.ServerName or "FiveM Server"
    end, Config.ServerName or "FiveM Server")
end

local function getQueueCount()
    return 0
end

local function buildPayload(override)
    local resourceStats = getResourceStats()

    local payload = {
        secret = Config.Secret,

        online = true,
        server_name = getServerName(),
        description = Config.Description or "Live Serverstatus",

        players = getPlayerCount(),
        max_players = getMaxPlayers(),
        queued_players = getQueueCount(),

        connect_command = Config.ConnectCommand or "Nicht gesetzt",

        uptime = getServerRuntime(),
        next_restart = getNextRestartText(),

        resources_started = resourceStats.started or 0,
        resources_total = resourceStats.total or 0,

        server_build = getServerBuild(),
        game_type = "FiveM",

        last_action = "online",
        action_reason = ""
    }

    if type(override) == "table" then
        for key, value in pairs(override) do
            payload[key] = value
        end
    end

    return payload
end

local function postPayload(payload, label)
    label = label or "Live-Status"

    if not Config.ApiUrl or Config.ApiUrl == "" then
        debugPrint("ABBRUCH: Config.ApiUrl fehlt.")
        return
    end

    if not Config.Secret or Config.Secret == "" or Config.Secret == "CHANGE_ME" then
        debugPrint("ABBRUCH: Config.Secret fehlt oder ist ungültig.")
        return
    end

    local body = json.encode(payload)

    if not body or body == "" then
        debugPrint("ABBRUCH: JSON konnte nicht erstellt werden.")
        return
    end

    debugPrint("Sende " .. label .. "...")
    debugPrint("Payload: " .. body)

    PerformHttpRequest(
        Config.ApiUrl,
        function(statusCode, responseText, headers)
            debugPrint("HTTP Code: " .. tostring(statusCode))
            debugPrint("Antwort: " .. tostring(responseText))

            if tonumber(statusCode) and tonumber(statusCode) >= 200 and tonumber(statusCode) < 300 then
                debugPrint(label .. " erfolgreich gesendet.")
            else
                debugPrint(label .. " konnte nicht gesendet werden.")
            end
        end,
        "POST",
        body,
        {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json"
        }
    )
end

local function sendStatus()
    local payload = buildPayload()
    postPayload(payload, "Live-Status")
end

local function sendOfflineStatus(action, reason)
    if shutdownAlreadySent then
        return
    end

    shutdownAlreadySent = true

    action = action or "shutdown"
    reason = reason or "Server wird beendet."

    local titleText = "Server wird heruntergefahren"

    if action == "restart" then
        titleText = "Server wird neugestartet"
    elseif action == "resource_stop" then
        titleText = "Status-Resource wurde gestoppt"
    end

    local payload = buildPayload({
        online = false,
        description = titleText,
        players = getPlayerCount(),
        queued_players = 0,
        uptime = getServerRuntime(),
        next_restart = "Jetzt",
        last_action = action,
        action_reason = reason,
        resources_started = 0,
        resources_total = getResourceStats().total or 0
    })

    postPayload(payload, "Offline-/Shutdown-Status")
end

CreateThread(function()
    Wait(5000)

    debugPrint("Resource gestartet.")
    sendStatus()

    while true do
        Wait((Config.SendIntervalSeconds or 60) * 1000)
        sendStatus()
    end
end)

AddEventHandler("playerJoining", function()
    Wait(3000)
    sendStatus()
end)

AddEventHandler("playerDropped", function()
    Wait(3000)
    sendStatus()
end)

-- Wird ausgelöst, wenn txAdmin den Server herunterfährt oder restartet.
AddEventHandler("txAdmin:events:serverShuttingDown", function(eventData)
    debugPrint("txAdmin:events:serverShuttingDown empfangen.")

    local reason = "Server wird über txAdmin beendet."
    local action = "shutdown"

    if type(eventData) == "table" then
        if eventData.reason then
            reason = tostring(eventData.reason)
        end

        if eventData.author then
            reason = reason .. " | Ausgelöst von: " .. tostring(eventData.author)
        end

        local lowerReason = string.lower(reason)

        if string.find(lowerReason, "restart") or string.find(lowerReason, "neustart") then
            action = "restart"
        end
    end

    sendOfflineStatus(action, reason)

    Wait(1500)
end)

-- Wird ausgelöst, wenn nur diese Resource gestoppt wird.
AddEventHandler("onResourceStop", function(stoppedResource)
    if stoppedResource ~= resourceName then
        return
    end

    debugPrint("onResourceStop für diese Resource erkannt.")
    sendOfflineStatus("resource_stop", "Die Status-Resource wurde gestoppt oder der Server fährt herunter.")

    Wait(1500)
end)

RegisterCommand("gfstatus_send", function(source)
    if source ~= 0 then
        print("Dieser Command ist nur in der Serverkonsole nutzbar.")
        return
    end

    shutdownAlreadySent = false
    sendStatus()
end, true)

RegisterCommand("gfstatus_offline", function(source, args)
    if source ~= 0 then
        print("Dieser Command ist nur in der Serverkonsole nutzbar.")
        return
    end

    local action = args[1] or "shutdown"
    local reason = table.concat(args, " ", 2)

    if reason == "" then
        reason = "Manueller Offline-Test."
    end

    shutdownAlreadySent = false
    sendOfflineStatus(action, reason)
end, true)

RegisterCommand("gfstatus_debug", function(source)
    if source ~= 0 then
        print("Dieser Command ist nur in der Serverkonsole nutzbar.")
        return
    end

    local payload = buildPayload()

    print("^2[" .. resourceName .. "] Debug Payload:^7")
    print(json.encode(payload))
end, true)