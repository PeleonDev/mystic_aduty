local savedOutfit = nil

local noClipSpeedMod, currentNoclipSpeed = 1
local hideESP = GetResourceKvpString('hideesp') == '1'
local noclipMode = GetResourceKvpString('noclipmode') == '1'

local aduty = {
	aduty = false,
	godmode = false,
	showNames = false,
	invis = false,
	noclip = false,
	espDistance = 150,
	guide = false -- guide mode
}

-- config key to ped component
local components = { mask = 1, pants = 4, bags = 5, shoes = 6, chain = 7, tshirt = 8, bproof = 9, decals = 10, torso = 11 }
local props = { helmet = 0, ears = 2 }

local function CaptureOutfit()
	local ped = PlayerPedId()
	local data = { components = {}, props = {} }

	for _, c in ipairs( { 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 } ) do
		data.components[c] = {
			GetPedDrawableVariation(ped, c),
			GetPedTextureVariation(ped, c),
			GetPedPaletteVariation(ped, c),
		}
	end

	for _, p in ipairs( { 0, 1, 2, 6 , 7 } ) do
		data.props[p] = {
			GetPedPropIndex(ped, p),
			GetPedPropTextureIndex(ped, p),
		}
	end

	return data
end

local function ApplyOutfit(data)
	if not data then return false end

	local ped = PlayerPedId()

	for id, c in pairs(data.components) do
		SetPedComponentVariation(ped, id, c[1], c[2], c[3] or 0)
	end

	for id, p in pairs(data.props) do
		if p[1] == -1 then
			ClearPedProp(ped, id)
		else
			SetPedPropIndex(ped, id, p[1], p[2], true)
		end
	end

	return true
end

local function GetCamDirection()
	local rot = GetGameplayCamRot(2)
	local z, x = math.rad(rot.z), math.rad(rot.x)
	local num = math.abs(math.cos(x))

	return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function ResetInvisible()
	local ped = PlayerPedId()

	SetEntityVisible(ped, true, false)
	NetworkSetEntityInvisibleToNetwork(ped, false)
end

CreateThread(function()
	RegisterCommand('noclipmode', function (source, args)
		noclipMode = not noclipMode

		SetResourceKvp('noclipmode', noclipMode and '1' or '0')

		ESX.ShowNotification(noclipMode and 'Alternativer Noclip-Modus aktiviert.' or 'Alternativer Noclip-Modus deaktiviert.')
	end)

	TriggerEvent('chat:addSuggestion', '/noclipmode', 'Zwischen alternativem Noclip-Modus umschalten')

	RegisterCommand('noclip', function(source, args)
		if not aduty.guide and (aduty.aduty or aduty.noclip) then
			aduty.noclip = not aduty.noclip

			TriggerServerEvent('mystic_aduty:sync', 'noclip', aduty.noclip)

			CreateThread(function()
				local offsets = {
					y = 0.5,
					z = 0.2,
				}

				local DisableControlAction = DisableControlAction
				local IsDisabledControlPressed = IsDisabledControlPressed

				local lastVehicle

				while aduty.aduty and aduty.noclip do
					local ped = PlayerPedId()
					local entity = GetVehiclePedIsIn(ped, false)

					if entity == 0 then
						entity = ped
					else
						lastVehicle = entity
					end

					DisableControlAction(0, 21)
					DisableControlAction(0, 19)
					DisableControlAction(0, 32)
					DisableControlAction(0, 33)
					DisableControlAction(0, 22)
					DisableControlAction(0, 36)

					currentNoclipSpeed = noClipSpeedMod

					if noclipMode then
						local coords = GetEntityCoords(entity)
						local x, y, z = coords.x, coords.y, coords.z

						local camDirect = GetCamDirection()
						local cx, cy, cz = camDirect.x, camDirect.y, camDirect.z

						if IsDisabledControlPressed(0, 21) then -- add speed
							currentNoclipSpeed = currentNoclipSpeed * 3
						end

						if IsDisabledControlPressed(0, 19) then -- remove speed
							currentNoclipSpeed = currentNoclipSpeed * 0.1
						end

						if IsDisabledControlPressed(0, 32) then
							x = x + (currentNoclipSpeed * cx)
							y = y + (currentNoclipSpeed * cy)
							z = z + (currentNoclipSpeed * cz)
						end

						if IsDisabledControlPressed(0, 33) then
							x = x - (currentNoclipSpeed * cx)
							y = y - (currentNoclipSpeed * cy)
							z = z - (currentNoclipSpeed * cz)
						end

						if IsDisabledControlPressed(0, 22) then
							z = z + currentNoclipSpeed
						end

						if IsDisabledControlPressed(0, 36) then
							z = z - currentNoclipSpeed
						end

						if coords.x ~= x or coords.y ~= y or coords.z ~= z then
							SetEntityCoordsNoOffset(entity, x, y, z, true, false, false)
						end

						SetEntityRotation(entity, 0.0, 0.0, 0.0, 0, false)
						SetEntityHeading(entity, GetGameplayCamRot(2).z)
					else
						local yoff = 0.0
						local zoff = 0.0

						if IsDisabledControlPressed(0, 21) then -- add speed
							currentNoclipSpeed = currentNoclipSpeed * 3
						end

						if IsDisabledControlPressed(0, 19) then -- remove speed
							currentNoclipSpeed = currentNoclipSpeed * 0.1
						end

						if IsDisabledControlPressed(0, 32) then
							yoff = yoff + offsets.y
						end

						if IsDisabledControlPressed(0, 33) then
							yoff = yoff - offsets.y
						end

						if IsDisabledControlPressed(0, 22) then
							zoff = zoff + offsets.z
						end

						if IsDisabledControlPressed(0, 36) then
							zoff = zoff - offsets.z
						end

						yoff = yoff * currentNoclipSpeed
						zoff = zoff * currentNoclipSpeed

						if yoff ~= 0.0 or zoff ~= 0.0 then
							local newPos = GetOffsetFromEntityInWorldCoords(entity, 0.0, yoff, zoff)

							SetEntityCoordsNoOffset(entity, newPos.x, newPos.y, newPos.z, true, false, false)
						end

						SetEntityRotation(entity, 0.0, 0.0, 0.0, 0, false)
						SetEntityHeading(entity, GetGameplayCamRot(2).z)
					end

					FreezeEntityPosition(entity, true)
					SetEntityCollision(entity, false)

					if lastVehicle ~= entity and DoesEntityExist(lastVehicle) then
						FreezeEntityPosition(lastVehicle, false)
						SetEntityCollision(lastVehicle, true)

						lastVehicle = nil
					end

					Wait(0)
				end

				local ped = PlayerPedId()
				FreezeEntityPosition(ped, false)
				SetEntityCollision(ped, true)

				if lastVehicle ~= ped and DoesEntityExist(lastVehicle) then
					FreezeEntityPosition(lastVehicle, false)
					SetEntityCollision(lastVehicle, true)

					lastVehicle = nil
				end
			end)

			if aduty.noclip then
				ESX.ShowNotification('Du hast NoClip angeschaltet.')
			else
				ESX.ShowNotification('Du hast NoClip ausgeschaltet.')
			end
		else
			ESX.ShowNotification('Du bist nicht im Admindienst.', 1)
		end
	end)

	TriggerEvent('chat:addSuggestion', '/noclip', 'NoClip umschalten')

	RegisterCommand('v', function(source, args)
		if not aduty.guide and aduty.aduty then
			aduty.invis = not aduty.invis

			TriggerServerEvent('mystic_aduty:sync', 'vanish', aduty.invis)

			if aduty.invis then
				SetEntityVisible(PlayerPedId(), false, false)
				NetworkSetEntityInvisibleToNetwork(PlayerPedId(), true)

				CreateThread(function()
					while aduty.invis do
						SetEntityVisible(PlayerPedId(), false, false)
						SetLocalPlayerVisibleLocally(true)

						Wait(0)
					end
				end)
			else
				ResetInvisible()
			end

			if aduty.invis then
				ESX.ShowNotification('Du bist nun unsichtbar.')
			else
				ESX.ShowNotification('Du bist nun wieder sichtbar.')
			end
		else
			ESX.ShowNotification('Du bist nicht im Admindienst.', 1)
		end
	end)

	TriggerEvent('chat:addSuggestion', '/v', 'Unsichtbar werden')
end)

function setUniform(group)
	local skins = Config.Skins[group]
	local model = GetEntityModel(PlayerPedId())

	local skin = skins and (
		(model == GetHashKey('mp_m_freemode_01') and skins.male) or
		(model == GetHashKey('mp_f_freemode_01') and skins.female)
	)

	if not skin then
		ESX.ShowNotification('Kein Outfit für diese Gruppe festgelegt.', 1)
		return
	end

	if not savedOutfit then
		savedOutfit = CaptureOutfit()
	end

	local ped = PlayerPedId()

	if skin.arms then
		SetPedComponentVariation(ped, 3, skin.arms, 0, 0)
	end

	for key, id in pairs(components) do
		if skin[key .. '_1'] then
			SetPedComponentVariation(ped, id, skin[key .. '_1'], skin[key .. '_2'] or 0, 0)
		end
	end

	for key, id in pairs(props) do
		local drawable = skin[key .. '_1']

		if drawable == -1 then
			ClearPedProp(ped, id)
		elseif drawable then
			SetPedPropIndex(ped, id, drawable, skin[key .. '_2'] or 0, true)
		end
	end
end

local function RestoreClothing()
	ApplyOutfit(savedOutfit)

	savedOutfit = nil
end

local function ResetInvincible()
	local ped = PlayerPedId()

	SetPlayerInvincible(PlayerId(), false)
	SetEntityCanBeDamaged(ped, true)
	SetPedCanBeKnockedOffVehicle(ped, 0)
	SetPedCanRagdoll(ped, true)
	SetPedCanRagdollFromPlayerImpact(ped, true)
	SetPedCanBeDraggedOut(ped, true)
	SetEntityProofs(ped, false, false, false, false, false, false, false, false)
end

local function DrawText3D(x, y, z, text, r, g, b)
	local onScreen, _x, _y = World3dToScreen2d(x, y, z)

	if onScreen then
		SetTextScale(0.23, 0.23)
		SetTextFont(0)
		SetTextProportional(1)
		SetTextCentre(true)
		SetTextColour(r, g, b, 255)
		SetTextOutline()
		SetTextEntry('STRING')
		AddTextComponentString(text)
		DrawText(_x, _y)
	end
end

local invisibleESP = {}
AddStateBagChangeHandler('stealthmode', nil, function(bagName, key, value)
	local player = GetPlayerFromStateBagName(bagName)
	if player == 0 then return end -- return if its not a player

	invisibleESP[GetPlayerServerId(player)] = value or nil
end)


-- ESP

local espInfo = {}
local groups = {}

local espThreadRunning = false

local function GetEspInfo(playerIdx, serverId)
	local entry = espInfo[serverId]
	local now = GetGameTimer()

	if entry and entry.expires > now then
		return entry
	end

	local group = tostring(groups[tostring(serverId)] or 'user')
	group = group:gsub('^%l', string.upper)

	entry = {
		name    = GetPlayerName(playerIdx) or 'Unbekannt',
		svId    = tostring(serverId),
		group   = group,
		expires = now + 1000,
	}

	espInfo[serverId] = entry

	return entry
end

local function GetEspHealth(ped)
	local health = math.max(0, GetEntityHealth(ped) - 100)
	local maxHealth = math.max(1, GetEntityMaxHealth(ped) - 100)

	return health, maxHealth
end

local function DrawEspBar(x, yHead, yFeet, percent, r, g, b)
	if percent <= 0 then return end

	local height = (yFeet - yHead) * percent

	DrawRect(x, yFeet - (height / 2), 0.001, height, r, g, b, 220)
end

local function StartEspThread()
	if espThreadRunning then return end
	espThreadRunning = true

	CreateThread(function()
		local players = {}
		local lastFetch = 0
		local lastGroups = 0

		while aduty.showNames do
			local drawing = false

			if not hideESP then
				local now = GetGameTimer()

				if lastFetch <= now then
					players = GetActivePlayers()
					lastFetch = now + 500
				end

				if lastGroups <= now then
					lastGroups = now + 3000

					ESX.TriggerServerCallback('mystic_aduty:getGroups', function(result)
						groups = result or {}
					end)
				end

				local playerPed = PlayerPedId()
				local coords = GetEntityCoords(playerPed)

				for i = 1, #players do
					local curPly = players[i]
					local ped = GetPlayerPed(curPly)

					if ped ~= 0 and ped ~= playerPed and DoesEntityExist(ped) then
						local serverId = GetPlayerServerId(curPly)
						local targetCoords = GetEntityCoords(ped)

						if serverId > 0
							and not invisibleESP[serverId]
							and #(targetCoords - coords) <= aduty.espDistance
							and IsEntityOnScreen(ped)
						then
							local info = GetEspInfo(curPly, serverId)

							DrawText3D(
								targetCoords.x, targetCoords.y, targetCoords.z + 1.1,
								('%s~n~[%s] %s'):format(info.group, info.svId, info.name),
								0, 255, 246
							)

							-- head dot

							local headPos = GetPedBoneCoords(ped, 0x796E, 0, 0, 0)

							DrawText3D(headPos.x, headPos.y, headPos.z, '•', 255, 255, 255)

							-- health & armor bars
							local head = GetPedBoneCoords(ped, 0x796E, 0.0, 0.0, 0.2)
							local feet = GetPedBoneCoords(ped, 0xCC4D, 0.0, 0.0, 0.0)
							local onScreenHead, sxHead, syHead = World3dToScreen2d(head.x, head.y, head.z)
							local onScreenFeet, _, syFeet = World3dToScreen2d(feet.x, feet.y, feet.z)

							if onScreenHead and onScreenFeet then
								local health, maxHealth = GetEspHealth(ped)
								local armor = GetPedArmour(ped) or 0

								local healthPercent = math.max(0, math.min(1, health / maxHealth))
								local armorPercent = math.max(0, math.min(1, armor / 100.0))

								DrawEspBar(sxHead + 0.002, syHead, syFeet, healthPercent, 0, 255, 0)
								DrawEspBar(sxHead - 0.002, syHead, syFeet, armorPercent, 0, 0, 200)
							end

							drawing = true
						end
					end
				end
			end

			Wait(drawing and 0 or 250)
		end

		espThreadRunning = false
	end)
end

-- a lua error kills a thread for good, restart it
CreateThread(function()
	while true do
		Wait(2000)

		if aduty.showNames and not espThreadRunning then
			ESX.ShowNotification('ESP-Thread war beendet, wird neu gestartet.', 1)
			StartEspThread()
		end
	end
end)

function ToggleAduty(notAduty, guide, group)
	if notAduty then
		aduty.aduty = false

		if aduty.godmode then
			ResetInvincible()
		end

		if aduty.invis then
			ResetInvisible()
		end

		aduty.invis = false
		aduty.noclip = false
		aduty.godmode = false
		aduty.showNames = false
		aduty.guide = false

		espInfo = {}
		groups = {}

		if not guide then
			ESX.ShowNotification('Du bist nun nicht mehr im Admindienst.')

			RestoreClothing()
		end
	else
		if not aduty.godmode then
			local ped = PlayerPedId()

			SetPlayerInvincible(PlayerId(), true)
			SetEntityCanBeDamaged(ped, false)
			SetPedCanBeKnockedOffVehicle(ped, 1)
			SetPedCanRagdoll(ped, false)
			SetPedCanRagdollFromPlayerImpact(ped, false)
			SetPedCanBeDraggedOut(ped, false)
			SetEntityProofs(ped, true, true, true, true, true, true, true, true)
		end

		aduty.aduty = true

		aduty.noclip = false
		aduty.godmode = true
		aduty.showNames = true
		aduty.guide = guide and true or false

		StartEspThread()

		if not guide then
			CreateThread(function()
				while aduty.aduty do
					DisableControlAction(0, 82)

					if IsDisabledControlJustPressed(0, 82) and not aduty.guide then
						ExecuteCommand('noclip')
					end

					Wait(0)
				end
			end)
		end

		if not guide then
			ESX.ShowNotification('Du hast den Admindienst angetreten.')

			setUniform(group)
		end
	end

	TriggerEvent('mystic_aduty:toggleAduty', aduty.aduty)
end

RegisterNetEvent('esx:onPlayerLogout', function() -- disable aduty
	if aduty.aduty or aduty.guide then
		ToggleAduty(true)
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then return end

	if aduty.aduty then
		ToggleAduty(true)
	end
end)

RegisterNetEvent('mystic_aduty:toggle', function(bool, guide)
	local notAduty = bool

	if notAduty == nil then
		notAduty = aduty.aduty
	end

	ESX.TriggerServerCallback('mystic_aduty:getPermissions', function(allowed, group)
		if allowed then
			ToggleAduty(notAduty, guide, group)
		else
			ESX.ShowNotification('Keine Rechte.', 1)
		end
	end, not notAduty, guide)
end)

CreateThread(function()
	RegisterCommand('aduty', function(source, args)
		TriggerEvent('mystic_aduty:toggle')
	end)

	RegisterCommand('hideesp', function()
		hideESP = not hideESP

		SetResourceKvp('hideesp', hideESP and '1' or '0')

		ESX.ShowNotification(hideESP and 'ESP-Informationen im Staff on Duty-Modus deaktiviert.' or 'ESP-Informationen im Staff on Duty-Modus aktiviert.')
	end)

	TriggerEvent('chat:addSuggestion', '/aduty', 'Staff on Duty Modus umschalten')
	TriggerEvent('chat:addSuggestion', '/hideesp', 'ESP-Informationen verstecken/zeichnen')
end)

AddEventHandler('mystic_aduty:info', function(cb)
	cb(aduty)
end)

function IsAdminOnDuty(guide)
	if guide then
		if aduty.aduty and aduty.guide then
			return true
		end
	elseif aduty.aduty then
		return true
	end

	return false
end
exports('IsAdminOnDuty', IsAdminOnDuty)

function IsInNoClip()
	return aduty.noclip and true or false
end
exports('IsInNoClip', IsInNoClip)

function IsInVanish()
	return aduty.invis and true or false
end
exports('IsInVanish', IsInVanish)
