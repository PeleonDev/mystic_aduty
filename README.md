# mystic_aduty

Standalone admin duty (aduty) for FiveM with ESX. Runs without any other resources, only `es_extended` is required.

> Inspired by **ModernV Aduty** from 2023. I was a team member back then, which is where the idea for this script came from.

## Features

- Admin duty via `/aduty` with a duty outfit per group (male/female) and automatic restore of the previous outfit
- Godmode while on duty
- NoClip (`/noclip` or the `,` key) with two modes (`/noclipmode`)
- Vanish (`/v`)
- ESP with group, server ID, name, health and armor bars
- Stealthmode (`/stealthmode`), hides your own ESP from other team members
- Guide mode for players who still have an "Einreise" (entry process), see below
- No logging, no external dependencies

## Requirements

- ESX Legacy (`es_extended`)

## Installation

1. Copy the `mystic_aduty` folder into your `resources` folder
2. Add it to your `server.cfg`:

```cfg
ensure mystic_aduty
```

## Commands

| Command | Description |
| --- | --- |
| `/aduty` | Enter or leave admin duty |
| `/noclip` | Toggle NoClip (on duty only) |
| `/noclipmode` | Switch between the two NoClip modes |
| `/v` | Toggle vanish (on duty only) |
| `/hideesp` | Hide or show ESP information |
| `/stealthmode [on/off]` | Hide your own ESP from other team members |

`/noclipmode` and `/hideesp` are saved locally per player.

## Guide mode

Guide mode is meant for team members who accompany players that still have an "Einreise" (entry process).

- Godmode and ESP are active, so the guide can see and follow players
- No duty outfit, no NoClip, no vanish
- It is not toggled by a command. Another script sets it via `exports['mystic_aduty']:SetAduty(src, state, true)` or the event `mystic_aduty:server:setAduty`
- Groups in `guideGroups` (e.g. `guide`) that have no admin duty cannot start or end the mode themselves
- If `guideForAdutyGroups` is enabled, every admin group can be put into guide mode as well
- `IsPlayerAdminOnDuty(src, true)` (server) and `IsAdminOnDuty(true)` (client) tell you whether someone is in guide mode

## Configuration

**config.lua**

`Config.Skins` contains the duty outfits. The group name is the ESX group name in lowercase. Every group with an entry here may use admin duty. Each group has `male` and `female`.

**server/main.lua** (`ServerConfig`)

| Option | Description |
| --- | --- |
| `espHideGroups` | Groups that may use `/stealthmode` |
| `extraAdutyGroups` | Groups that may use admin duty without an outfit entry |
| `guideGroups` | Groups that may use guide mode |
| `guideForAdutyGroups` | May every admin use guide mode? |
| `cooldown` | Action cooldown in ms |

## Exports

**Server**

```lua
exports['mystic_aduty']:IsPlayerAdminOnDuty(src, guideOnly)
exports['mystic_aduty']:GetAdminsOnDuty()
exports['mystic_aduty']:IsPlayerInVanish(src)
exports['mystic_aduty']:IsPlayerInNoclip(src)
exports['mystic_aduty']:IsEspHidden(src)
exports['mystic_aduty']:SetEspHidden(src, state, silent)
exports['mystic_aduty']:IsAdutyAllowed(src)
exports['mystic_aduty']:SetAduty(src, state, guide)
```

**Client**

```lua
exports['mystic_aduty']:IsAdminOnDuty(guide)
exports['mystic_aduty']:IsInNoClip()
exports['mystic_aduty']:IsInVanish()
```

## Events

```lua
-- server, fired on every duty change
AddEventHandler('mystic_aduty:adutyChanged', function(src, state, group, guide) end)

-- client, fired on every duty change
AddEventHandler('mystic_aduty:toggleAduty', function(state) end)

-- server, set duty via event (guide mode)
TriggerEvent('mystic_aduty:server:setAduty', src, state, guide)
```

## Notes

- Notifications use `ESX.ShowNotification`. Errors are sent as `ESX.ShowNotification('msg', 1)`.
- The duty outfit is applied directly via ped components. Hair is not changed.

## Credits

Inspired by ModernV Aduty (2023). I was a team member back then, which is why I had the idea.
