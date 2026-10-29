# CSS Mani Admin Plugin Remastered

**Mani Admin Plugin running again on today's Counter-Strike: Source, in 32-bit and 64-bit.**

If you ran a Counter-Strike: Source server between 2005 and 2014, you probably know
[Mani Admin Plugin](https://web.archive.org/web/2014/http://www.mani-admin-plugin.com/): the all-in-one admin tool with
its `admin` menu, the `ma_` commands, map votes, reserved slots, weapon restrictions, player stats, skins, adverts,
quake sounds and fun commands (slap, burn, freeze, beacon, time bomb…). Its last release for CS:S (1.2.22.15, 2013)
no longer works on the current game: Valve kept changing the engine, and in 2025 CS:S got a 64-bit server that the
old 32-bit binary cannot load at all.

This repository rebuilds Mani Admin Plugin from its last sources (1.2.23) for the current CS:S (the 2025 engine
branch, `ServerVersion 11003710`), as **version 1.3.0**, for both server architectures. Everything that broke on the
modern engine is fixed and documented, and each release is a `cstrike/` folder you copy onto your server.

- No Docker, no Metamod, no SourceMod needed: it is a plain server plugin (VSP), loaded by the game itself.
- Works next to Metamod:Source and SourceMod if you already run them.
- Same configuration files as the original Mani Admin Plugin: an existing setup can be kept.

## Contents

- [Status](#status)
- [Requirements](#requirements)
- [Installation](#installation)
- [First steps](#first-steps)
- [Upgrading from an old Mani Admin Plugin](#upgrading-from-an-old-mani-admin-plugin)
- [Good to know](#good-to-know)
- [Limitations](#limitations)
- [What was fixed](#what-was-fixed)
- [Building from source](#building-from-source)
- [Repository layout](#repository-layout)
- [Credits and license](#credits-and-license)

## Status

Tested on CS:S `11003710` (Linux dedicated server, 32-bit `srcds_run` and 64-bit `srcds_run_64`), with bots and with
a human player. After each command, the real state of the player was read back from the game (health, money,
weapons, armor, position, colour, gravity, move type, team…) by a test plugin ([`tools/mani_verify.sp`](tools/mani_verify.sp)).

| Test | 32-bit | 64-bit |
|---|---|---|
| Loading, `gametypes.txt`, symbols, advanced effects (`te`) | OK | OK |
| `ma_autovfunc` (Mani's own check of every virtual function index against the game) | no wrong index | no wrong index |
| Health, cash, `ma_give` (weapons, armor, ammo), slap, slay, burn, freeze, gravity, colour, render mode | OK | OK |
| Teleport, beacon, time bomb, `ma_setskin`, team swap, spectator, kick | OK | OK |
| Weapon restrictions (`ma_restrict`, `ma_restrictall`, knives / pistols rounds), weapon names and prices | OK | OK |
| Map lists, `ma_setnextmap`, `ma_map`, map changes | OK | OK |
| Admins from `clients.txt` (including `[U:1:…]` SteamIDs), `admin` menu used in game | OK | OK |
| Endurance: 10 bots, Mani commands in a loop, map changes | no crash (3 min) | no crash (8 min) |

Not tested: the MySQL database mode (32-bit only, see [Limitations](#limitations)), votes with several human
players, and the statistics/ranks over a long period.

## Requirements

- A **Linux** Counter-Strike: Source dedicated server, up to date (Steam app `232330`, installed with SteamCMD).
- The package matching the way you start the server:

  | You start the server with | Server binary | Package |
  |---|---|---|
  | `./srcds_run` (the default) | `srcds_linux`, 32-bit | `mani_admin_plugin_1.3.0_css_linux_32bit.zip` |
  | `./srcds_run_64` | `srcds_linux64`, 64-bit | `mani_admin_plugin_1.3.0_css_linux_64bit.zip` |

  If you do not know, it is the 32-bit one: Valve's CS:S server starts in 32 bits.
- glibc 2.29 or newer, which CS:S itself already requires: any distribution able to run the game will do.

Windows servers are not supported (see [Limitations](#limitations)).

> [!NOTE]
> **About the 64-bit server.** Valve ships CS:S with its 64-bit libraries (`bin/linux64/`, `cstrike/bin/linux64/`)
> but without the 64-bit launcher ([ValveSoftware/Source-1-Games#7057](https://github.com/ValveSoftware/Source-1-Games/issues/7057)).
> Server owners take `srcds_linux64`, `srcds_run_64` and `bin/linux64/libsteam_api.so` from the Team Fortress 2
> dedicated server (`steamcmd +login anonymous +app_update 232250`), and the 64-bit engine also looks for its
> libraries without the `_srv` suffix (`ln -s engine_srv.so bin/linux64/engine.so`, and so on for each library).
> This is not specific to Mani Admin Plugin: if your server already runs in 64 bits, you have nothing to do.

## Installation

1. Download the package for your server from the [**Releases**](../../releases) page.
2. Extract it: you get a `cstrike/` folder.
3. Copy that `cstrike/` folder over the `cstrike/` folder of your server (merge the folders: no file of the game is
   overwritten).
4. Restart the server (a map change is not enough: plugins are loaded at startup).

Check in the server console:

```
plugin_print
```

It must list:

```
0:	"Mani Admin Plugin 2026 V1.3.0 VSP CS:S, github.com/WareZ57/CSS-Mani-Admin-Plugin-Remastered"
```

The console also shows `Loading Mani Admin Plugin 2026 V1.3.0` at startup, and `mani_admin_plugin_version` returns
`1.3.0 VSP`.

<details>
<summary>Installing from the repository instead of a release</summary>

The repository holds the same files: copy `cstrike/` over your server's `cstrike/`, then copy
`bin/32-bit/cstrike/` **or** `bin/64-bit/cstrike/` over it too. Only install one architecture: the other server
binary cannot load it and prints `Unable to load plugin`.

</details>

### What gets installed

| Path (in `cstrike/`) | What it is |
|---|---|
| `addons/mani_admin_plugin_i486.so` + `addons/mani_admin_plugin.vdf` | the plugin, 32-bit package |
| `addons/mani_admin_plugin_x64.so` + `addons/mani_admin_plugin_x64.vdf` | the plugin, 64-bit package |
| `cfg/mani_server.cfg` | all settings (cvars), executed at every map start |
| `cfg/mani_skins.cfg`, `cfg/mani_quake_sounds.cfg` | skins and quake sounds settings, executed by `mani_server.cfg` |
| `cfg/mani_admin_plugin/` | admins (`clients.txt`, created on first use), `gametypes.txt`, language, adverts, votes, restrictions, menus… |
| `custom/mani_maplist/` | the map lists of the admin menus and votes (`maplist.txt`, `mapcycle.txt`) |
| `materials/`, `sound/` | decals and sounds used by the plugin |

## First steps

### Make yourself an admin

Admins are stored in `cfg/mani_admin_plugin/clients.txt`. The quickest way is the server console (or RCON):

```
ma_client addclient YourName
ma_client addsteam YourName STEAM_0:1:12345678
ma_client setaflag YourName +#
ma_client setiflag YourName +#
```

`+#` gives every admin flag (and every immunity flag). Use `ma_client status YourName` to check, and
`ma_client aflag` to list the flags if you want to give fewer rights.

> [!IMPORTANT]
> **Also add your SteamID in the new format.** Today's engine identifies players as `[U:1:N]` (Steam3), not as
> `STEAM_0:X:Y`, and Mani compares the text as it is. `ma_client addsteam` only accepts the old format, so add the
> new one by hand in `clients.txt`, then change the map:
>
> ```
> "YourName"
> {
> 	"name"	"YourName"
> 	"steam"
> 	{
> 		"steam1"	"STEAM_0:1:12345678"
> 		"steam2"	"[U:1:24691357]"
> 	}
> 	...
> }
> ```
>
> `N = Y × 2 + X`: `STEAM_0:1:12345678` → `[U:1:24691357]`. The `status` command shows the `[U:1:N]` of every
> connected player.

### Use it

- In game, type `admin` in the console (bind it to a key: `bind F2 admin`) to open the admin menu.
- Every function is also a command: `ma_slap <player> [damage]`, `ma_kick`, `ma_ban`, `ma_map`, `ma_setnextmap`,
  `ma_restrict`, `ma_give`… They work from the server console, from the client console of an admin, and in chat
  (`ma_slap bob`, or `@ma_slap bob`: the prefix is `mani_say_command_prefix`). `ma_help` lists them, `ma_help <command>` explains one.
- `ma_rcon <command>` runs a server command, exactly as typed: `ma_rcon mp_restartgame 1`.
- Players type `settings` in chat for their own options (skins, quake sounds…).

### Configure it

Everything is in `cfg/mani_server.cfg`, commented. Most modules are off by default (adverts, stats, reserved slots,
skins, quake sounds…): turn on what you need, then change the map. The files of `cfg/mani_admin_plugin/` hold the
lists (adverts, votes, banned words, restrictions, client commands…), each one documented at its top.

## Upgrading from an old Mani Admin Plugin

1. Delete the old plugin files from `cstrike/addons/`: `mani_admin_plugin_i486.so`, `mani_admin_plugin.dll`,
   `mani_admin_plugin.vdf`, and `addons/metamod/mani_admin_plugin.vdf` plus `addons/mani_admin_plugin/bin/` if you
   used the Metamod version.
2. Copy the new package (see [Installation](#installation)) but **keep your own** `mani_server.cfg`, `clients.txt`
   and lists if you changed them.
3. Replace in any case `cfg/mani_admin_plugin/gametypes.txt` (the engine offsets, see below) and
   `cfg/mani_admin_plugin/language/english.cfg` (1.2.23 texts), and fill `custom/mani_maplist/` with your maps.
4. Add the `[U:1:N]` SteamID of each admin (see above).

## Good to know

- **Map lists.** The admin menus and votes read `custom/mani_maplist/maplist.txt` and `mapcycle.txt`: put your maps
  there, one per line (the package lists the stock maps). The `custom/` folder is searched before the rest of the game,
  so these files win over any other `maplist.txt`. The game itself reads `cfg/mapcycle.txt`.
- **Client commands menu** (`cexeclist_*.txt`). Mani makes the player's game type the command, and today's clients
  only accept the few commands flagged `FCVAR_SERVER_CAN_EXECUTE`: `name` and most others are ignored.
  The examples of the original package were removed for that reason.
- **Fast download.** Set `sv_downloadurl` if you enable skins or quake sounds with auto download, as for any custom
  content.
- **Server browser.** `mani_admin_plugin_version` is a replicated cvar: it shows `1.3.0 VSP` in server rules.

## Limitations

- **Windows** servers are not supported: only the Linux plugins were rebuilt and tested (the offsets of
  `gametypes.txt` for Windows are untouched and probably wrong).
- **MySQL** (`database.txt`, shared admins and bans between servers): the 32-bit plugin is built with the MySQL 5.1
  client shipped with Mani's sources, not tested with a database; the 64-bit plugin has no MySQL client and always uses
  its text files.
- **Reserved slots, "fill slot" mode** (`mani_reserve_slots_allow_slot_fill`): its hooks targeted engine functions that
  no longer exist and are not built. The classic mode (kick a player to free a slot) works.
- **Quake sounds**: the settings are included, the sound pack itself (a separate download at the time) is not.
- **Metamod version**: only the server plugin (VSP) is built. It does everything the Metamod version did, and loads
  next to Metamod:Source and SourceMod.

## What was fixed

The full list, with the reasons, is in [`docs/TECHNICAL.md`](docs/TECHNICAL.md) and [`CHANGELOG.md`](CHANGELOG.md). In short:

- **The plugin did not load**: the 2025 engine no longer adds `_i486` to the file name of a plugin (the `.vdf` now
  gives the full name), and the 64-bit server needs a 64-bit build.
- **19 virtual function offsets** of `gametypes.txt` were wrong (`CCSPlayer` and the weapons gained functions since
  2013): give, teleport, ignite, weapon drop/switch/restriction… now call the right functions. The same offsets are
  valid in 32 and 64 bits.
- **Map hooks and game rules**: `LevelInit` moved in `IServerGameDLL`, the game rules pointer is now read from its symbol.
- **Map lists were empty** in the menus: the package shipped empty `custom/mani_maplist/` files, and the current SDK's
  `IsMapValid` expects `maps/<name>.bsp`.
- **64-bit port**: ELF64 symbol reading, member function pointers, a weapon info structure copied with 32-bit
  offsets, address sorting that truncated pointers, private SDK fields reached without a modified SDK.
- **Crash** in `ma_restrict` and the other weapon commands when a weapon is missing.
- Version **1.3.0** (`Mani Admin Plugin 2026 V1.3.0`), and the out-of-date warnings point to this repository instead
  of the dead mani-admin-plugin.com.

## Building from source

Requirements: Docker (the build runs in AlliedModders' build container, the one used for SourceMod) and git.

```
./build.sh             # both: build/x86/mani_admin_plugin_i486.so and build/x86_64/mani_admin_plugin_x64.so
./build.sh x86_64      # one architecture (x86 or x86_64)
tools/package.sh       # the two release zips in dist/, from cstrike/ and bin/
```

`build.sh` fetches the SDKs into `deps/` ([`tools/fetch_deps.sh`](tools/fetch_deps.sh)): AlliedModders'
[hl2sdk](https://github.com/alliedmodders/hl2sdk/tree/css) (`css` branch, x86 and x86_64 libraries) and
[Metamod:Source](https://github.com/alliedmodders/metamod-source/tree/1.12-dev) 1.12 for SourceHook. Without Docker,
run `make ARCH=x86` / `make ARCH=x86_64` on a Debian 11-like system with g++ 10 and the 32-bit multilib.

After a CS:S update, [`tools/vtable.py`](tools/vtable.py) reads a vtable of the game to check the offsets of
`gametypes.txt` (`pip install pyelftools`):

```
python3 tools/vtable.py cstrike/bin/linux64/server_srv.so _ZTV9CCSPlayer 'GiveNamedItem|Teleport'
```

then `ma_autovfunc <userid of a bot>` in game.

## Repository layout

| Path | Content |
|---|---|
| `cstrike/` | files common to both packages (configuration, map lists, sounds, decals) |
| `bin/32-bit/`, `bin/64-bit/` | the built plugin and its `.vdf` for each architecture |
| `src/` | Mani Admin Plugin sources; `src/compat/` holds what replaces Mani's modified SDK |
| `Makefile`, `build.sh`, `tools/` | build, packaging, offset and test tools |
| `docs/TECHNICAL.md` | every fix in detail |

The first commit is the original code and data as released by Mani, so `git diff` against it shows every change.

## Credits and license

- **Mani** and the Mani Admin Plugin contributors, for the plugin (2004–2014).
- **AlliedModders**, for hl2sdk, SourceHook and the build container.

Mani Admin Plugin is free software under the **GNU General Public License v3** ([`LICENSE`](LICENSE)); so is this
remaster. It is not affiliated with Valve or with the original authors.
