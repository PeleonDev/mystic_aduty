local ServerConfig = {
    -- groups that can use stealthmode
    espHideGroups = {
        ['serverleader'] = true,
        ['teamleader'] = true,
        ['developer'] = true,
        ['superadmin'] = true,
    },

    extraAdutyGroups = {
        -- ['gruppenname'] = true,
    },

    -- groups that can use guide mode
    guideGroups = {
        ['guide'] = true,
    },

    -- can every admin use guide mode?
    guideForAdutyGroups = true,

    -- in ms
    cooldown = 500,
}

local adminsOnDuty = {}
local espDisabled = {}
local lastAction = {}
local scriptToggle = {}

local function GrantScriptToggle(src)
    scriptToggle[src] = GetGameTimer() + 5000
end

local function ConsumeScriptToggle(src)
    local expires = scriptToggle[src]
    scriptToggle[src] = nil

    return expires ~= nil and GetGameTimer() <= expires
end

local function Notify(src, message, err)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if err then
        xPlayer.showNotification(message, 1)
    else
        xPlayer.showNotification(message)
    end
end

local function GetGroup(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end

    local group = xPlayer.getGroup()
    if type(group) ~= 'string' then return 'user' end

    return string.lower(group)
end

local function IsAdutyGroup(group)
    if not group or group == '' or group == 'user' then return false end
    if Config.Skins[group] then return true end
    if ServerConfig.extraAdutyGroups[group] then return true end

    return false
end

local function IsGuideGroup(group)
    if not group or group == '' or group == 'user' then return false end

    if ServerConfig.guideGroups[group] then return true end

    if ServerConfig.guideForAdutyGroups and IsAdutyGroup(group) then return true end

    return false
end

local function IsGuideOnlyGroup(group)
    if not group then return false end
    if not ServerConfig.guideGroups[group] then return false end

    return not IsAdutyGroup(group)
end

local function IsEspHideGroup(group)
    return (group and ServerConfig.espHideGroups[group] and true) or false
end

local function CheckCooldown(src, action)
    local now = GetGameTimer()

    lastAction[src] = lastAction[src] or {}

    if lastAction[src][action] and (now - lastAction[src][action]) < ServerConfig.cooldown then
        return false
    end

    lastAction[src][action] = now
    return true
end

local function SetOnDuty(src, group, guide)
    adminsOnDuty[src] = {
        group = group,
        guide = guide and true or false,
        since = os.time(),
        vanish = false,
        noclip = false,
    }

    Player(src).state:set('adminOnDuty', true, false)
    Player(src).state:set('adminGroup', group, false)

    TriggerEvent('mystic_aduty:adutyChanged', src, true, group, guide and true or false)
end

local function SetOffDuty(src)
    local data = adminsOnDuty[src]
    adminsOnDuty[src] = nil

    if GetPlayerName(src) then
        Player(src).state:set('adminOnDuty', false, false)
        Player(src).state:set('adminGroup', nil, false)
    end

    TriggerEvent('mystic_aduty:adutyChanged', src, false, data and data.group or nil, data and data.guide or false)

    return data
end

ESX.RegisterServerCallback('mystic_aduty:getPermissions', function(source, cb, enable, guide)
    local src = source
    local group = GetGroup(src)

    if not group then
        return cb(false)
    end

    guide = guide and true or false

    local fromScript = ConsumeScriptToggle(src)

    if not enable then
        local current = adminsOnDuty[src]

        if current and current.guide and not fromScript and IsGuideOnlyGroup(group) then
            Notify(src, 'Der Guide-Modus wird automatisch verwaltet und kann nicht selbst beendet werden.', true)
            return cb(false)
        end

        SetOffDuty(src)

        return cb(true, group)
    end

    if not CheckCooldown(src, 'aduty') then
        return cb(false)
    end

    if guide and not fromScript and IsGuideOnlyGroup(group) then
        Notify(src, 'Der Guide-Modus kann nicht selbst aktiviert werden.', true)
        return cb(false)
    end

    local allowed

    if guide then
        allowed = IsGuideGroup(group)
    else
        allowed = IsAdutyGroup(group)
    end

    if not allowed then
        return cb(false)
    end

    SetOnDuty(src, group, guide)

    cb(true, group)
end)

-- groups of all players, only for admins on duty
ESX.RegisterServerCallback('mystic_aduty:getGroups', function(source, cb)
    local groups = {}

    if adminsOnDuty[source] then
        for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
            groups[tostring(xPlayer.source)] = xPlayer.getGroup()
        end
    end

    cb(groups)
end)

-- vanish and noclip state from the client
RegisterNetEvent('mystic_aduty:sync', function(key, value)
    local data = adminsOnDuty[source]

    if not data or (key ~= 'vanish' and key ~= 'noclip') then return end

    data[key] = value == true
end)

local function SetEspDisabled(src, state, silent)
    state = state and true or false

    espDisabled[src] = state or nil
    Player(src).state:set('stealthmode', state, true)

    if not silent then
        Notify(src, state and 'Stealth-Mode aktiviert.' or 'Stealth-Mode deaktiviert.')
    end

    return state
end

RegisterCommand('stealthmode', function(source, args)
    local src = source

    if src == 0 then
        return
    end

    local group = GetGroup(src)

    if not IsEspHideGroup(group) then
        Notify(src, 'Keine Rechte.', true)

        return
    end

    if not CheckCooldown(src, 'stealthmode') then return end

    local state

    if args[1] then
        local arg = string.lower(args[1])

        if arg == 'on' or arg == 'an' or arg == '1' or arg == 'true' then
            state = true
        elseif arg == 'off' or arg == 'aus' or arg == '0' or arg == 'false' then
            state = false
        end
    end

    if state == nil then
        state = not espDisabled[src]
    end

    SetEspDisabled(src, state)
end, false)

local function AddStealthSuggestion(target)
    TriggerClientEvent('chat:addSuggestion', target, '/stealthmode', 'Eigenes ESP für andere Teammitglieder verstecken', {
        { name = 'status', help = 'optional: on / off' },
    })
end

AddStealthSuggestion(-1)

AddEventHandler('esx:playerLoaded', function(playerId)
    AddStealthSuggestion(playerId)
end)

AddEventHandler('playerDropped', function()
    local src = source

    if adminsOnDuty[src] then
        SetOffDuty(src)
    end

    espDisabled[src] = nil
    lastAction[src] = nil
    scriptToggle[src] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for src in pairs(adminsOnDuty) do
        SetOffDuty(src)
    end
end)

-- exports for other resources

exports('IsPlayerAdminOnDuty', function(src, guideOnly)
    local data = adminsOnDuty[src]
    if not data then return false end
    if guideOnly then return data.guide end

    return true
end)

exports('GetAdminsOnDuty', function()
    local result = {}

    for src, data in pairs(adminsOnDuty) do
        result[src] = {
            group = data.group,
            guide = data.guide,
            since = data.since,
            vanish = data.vanish,
            noclip = data.noclip,
        }
    end

    return result
end)

exports('IsEspHidden', function(src)
    return espDisabled[src] and true or false
end)

exports('IsPlayerInVanish', function(src)
    local data = adminsOnDuty[src]
    return (data and data.vanish) and true or false
end)

exports('IsPlayerInNoclip', function(src)
    local data = adminsOnDuty[src]
    return (data and data.noclip) and true or false
end)

exports('SetEspHidden', function(src, state, silent)
    if not GetPlayerName(src) then return false end

    return SetEspDisabled(src, state, silent)
end)

exports('IsAdutyAllowed', function(src)
    return IsAdutyGroup(GetGroup(src))
end)

exports('SetAduty', function(src, state, guide)
    if not GetPlayerName(src) then return false end

    GrantScriptToggle(src)

    TriggerClientEvent('mystic_aduty:toggle', src, not state, guide)

    return true
end)

AddEventHandler('mystic_aduty:server:setAduty', function(src, state, guide)
    if not GetPlayerName(src) then return end

    GrantScriptToggle(src)

    TriggerClientEvent('mystic_aduty:toggle', src, not state, guide)
end)
