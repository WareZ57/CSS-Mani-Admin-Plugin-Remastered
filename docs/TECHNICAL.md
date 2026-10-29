# Technical notes

What broke on today's Counter-Strike: Source, why, and how it was fixed. Game version: `11003710` (2025 engine
branch), Linux. `git diff` against the first commit (the original release) shows every change.

## 1. Loading

The 2013 engine appended `_i486` to the file name given in a plugin `.vdf`; the 2025 engine does not. The original
`.vdf` (`"file" "../cstrike/addons/mani_admin_plugin"`) therefore pointed to a missing file and the console only said
`Unable to load plugin`. The `.vdf` files now give the full name (`mani_admin_plugin_i486.so`,
`mani_admin_plugin_x64.so`). The engine also refuses `plugin_load` while a map is running: plugins are loaded at
startup from the `.vdf` files.

A 64-bit server (`srcds_linux64`) can only load 64-bit plugins, hence the new `mani_admin_plugin_x64.so`. The 32-bit
server prints `wrong ELF class` for a 64-bit plugin and the other way round: install one architecture only.

## 2. `gametypes.txt`

Mani calls game functions through virtual function indices and symbols listed in `gametypes.txt`. Indices were read
from the vtables of `cstrike/bin/server_srv.so` (`tools/vtable.py`) and checked in game with `ma_autovfunc`:

| Key | 2013 | Now | Function |
|---|---|---|---|
| `teleport` | 109 | 112 | `CBaseFlex::Teleport` |
| `eye_position` / `eye_angles` | 131 / 132 | 135 / 136 | `CBasePlayer::EyePosition` / `EyeAngles` |
| `get_velocity` | 141 | 145 | `CBaseAnimating::GetVelocity` |
| `my_combat_character` | 72 | 75 | `CBaseCombatCharacter::MyCombatCharacterPointer` |
| `ignite` | 209 | 217 | `CBaseAnimating::Ignite` |
| `give_ammo` | 252 | 260 | `CBaseCombatCharacter::GiveAmmo` |
| `weapon_canuse` | 260 | 268 | `CCSPlayer::Weapon_CanUse` |
| `weapon_drop` / `weapon_switch` | 263 / 264 | 271 / 272 | `CBasePlayer::Weapon_Drop` / `Weapon_Switch` |
| `get_weapon_slot` | 268 | 276 | `CBaseCombatCharacter::Weapon_GetSlot` |
| `remove_player_item` | 270 | 278 | `CBasePlayer::RemovePlayerItem` |
| `set_observer_target` | 375 | 384 | `CBasePlayer::SetObserverTarget` |
| `give_item` | 401 | 410 | `CCSPlayer::GiveNamedItem` |
| `user_cmds` | 418 | 427 | `CBasePlayer::ProcessUsercmds` |
| `commit_suicide` | 439 | 448 | `CCSPlayer::CommitSuicide` |
| `weapon_get_name` | 321 | 330 | `CBaseCombatWeapon::GetName` |
| `get_primary_ammo_type` / `get_secondary_ammo_type` | 328 / 329 | 337 / 338 | `CBaseCombatWeapon::GetPrimaryAmmoType` / `GetSecondaryAmmoType` |

`set_model_index` (9) and `map_desc` (12) did not change. The 64-bit vtables have the same indices (same
Itanium C++ ABI and the same classes), so one `gametypes.txt` serves both plugins.

Other entries:

- `spawn_point_control` hooks `IServerGameDLL::LevelInit`: Valve added `ReplayInit` before it, index 2 → 3 (with 2,
  Mani hooked `GameInit` with the wrong signature).
- `CGameRules_gGameRules` read the game rules pointer at +6 inside `SwitchToNextBestWeapon`, code that no longer
  exists: the `g_pGameRules` symbol is used directly.
- `CGlobalEntityList_FindEntityByClassname` changed its prototype (a filter was added): its symbol is not found and the
  startup line `Sig [CGlobalEntityList_FindEntityByClassname] Failed!!` remains. Nothing in Mani calls it.

## 3. Map lists

The admin menus (change map, set next map) and votes were empty:

- The package shipped **empty** `custom/mani_maplist/maplist.txt` and `mapcycle.txt`, and `custom/` is searched before
  `cstrike/` by the game's file system, so these empty files hid any other list. They now list the stock maps.
- The current engine exposes two `IVEngineServer` versions: `VEngineServer022` (what the 2013 binary got), whose
  `IsMapValid` takes a map name, and `VEngineServer023` (what the current SDK gets), whose `IsMapValid` takes a path.
  Built with the current SDK, every map was rejected (`CModelLoader::Map_IsValid: No such map 'de_dust2'`).
  `ManiIsMapValid()` (`mani_maps.cpp`) passes `maps/<name>.bsp`. `IsMapValid` is the only function that differs
  between the two interfaces (checked in `engine_srv.so`).

## 4. Building with the current SDK

Mani compiled against its own modified copy of the 2007–2013 SDK. The plugin is now built against AlliedModders'
[hl2sdk](https://github.com/alliedmodders/hl2sdk/tree/css) (`css` branch) and SourceHook from Metamod:Source 1.12:

- `std::make_pair<A, B>(…)` with explicit template arguments no longer compiles in C++11: the arguments are deduced.
- `PLUGIN_BAD_ADMIN`, a value Mani added to `PLUGIN_RESULT`, is defined in `src/compat/sdk_compat.h` (Mani turns it
  into `PLUGIN_STOP` before returning to the engine).
- `ConCommandBase::m_nFlags` and `ConVar::m_fnChangeCallback` are private in the SDK: `src/compat/convar_access.h`
  reaches them with the standard explicit-instantiation technique instead of a modified header.
- `IServerPluginCallbacks` version 004: `OnEdictAllocated` / `OnEdictFreed`.
- `CSteamID::Render` uses the current layout of `CSteamID`.
- `g_pCVar` is defined by the SDK's `tier1`, no longer by Mani.
- SourceHook: static hooks only (`SH_DECL_HOOK`); the run-time hook generator is neither needed nor available for
  Linux x86_64.
- The reserved slots "fill slot" mode detoured `CBaseServer::ConnectClient` and `NET_SendPacket` with an x86 code
  generator; both functions changed and their old symbols are gone, so the detours could not attach on today's
  engine. They are compiled out (`MANI_NO_DETOURS`); the classic reserved slots mode (kick) is unaffected.
- Console output: Mani found the engine's `ConMsg` by decoding the x86 `call` inside the `echo` command; that code
  changed, and it cannot work in 64-bit. `Msg()` prints to the same console.

## 5. 64-bit port

- **Symbols** (`mani_linuxutils.cpp`): the ELF structures were `Elf32_*` only; they are now those of the build
  (`ElfW()`). The table sorted by address compared two pointers by subtracting them into an `int`, which truncates in
  64-bit and broke the binary search: it compares them.
- **Member function pointers** (`mani_vfuncs.cpp`): with the Itanium ABI a member function pointer is
  `{address, this adjustment}`; Mani only set the address on Linux and left the adjustment uninitialised (an 8-byte
  word of garbage in 64-bit). Both are set.
- **Vtables** in `ma_vfuncs` / `ma_autovfunc` were read through `DWORD` (32 bits): read as pointers.
- **`CCSWeaponInfo`**: Mani copies the start of the game's structure with padding arrays. The name of a weapon is at
  byte 6 in 32-bit and 10 in 64-bit (8-byte vtable pointer), and `FileWeaponInfo_t` is 48 bytes larger in 64-bit
  (pointer members): the price moves from byte 2308 to 2356. Sizes measured with the SDK's headers, values checked
  with `ma_listweapons` (`weapon_xm1014` 3000, `weapon_usp` 500…).
- **Game binaries**: looked up in `bin/linux64/` and `cstrike/bin/linux64/`.
- **MySQL**: the bundled client library is 32-bit; the 64-bit build uses `src/compat/nomysql/` (every connection fails
  cleanly, Mani keeps its text files).

## 6. Other fixes

- `ma_restrict`, `ma_unrestrict`, the restrict-all commands and the weapon menus dereferenced every weapon slot,
  including slots of weapons the game did not return: crash. Missing weapons are skipped.
- The `cexeclist_*.txt` examples (`name Flower`): clients only run commands flagged `FCVAR_SERVER_CAN_EXECUTE` when
  a server sends them, `name` is not one of them. Commented out.

## 7. SteamIDs

The 2025 engine returns SteamIDs as `[U:1:N]` (`GetPlayerNetworkIDString`). Mani compares them as text with the ones
of `clients.txt` and only accepts the `STEAM_` format in `ma_client addsteam`, so admins must also be listed with their
`[U:1:N]` form, added by hand (`N = Y × 2 + X` for `STEAM_0:X:Y`). See the README.
