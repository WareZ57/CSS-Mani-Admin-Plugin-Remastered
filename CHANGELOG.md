# Changelog

## 1.3.0 — 2026-10-29

First release of the remaster, built from Mani Admin Plugin 1.2.23 (2014 sources) for Counter-Strike: Source
`11003710` (2025 engine), Linux.

### Added

- 64-bit server plugin (`mani_admin_plugin_x64.so`, for `srcds_run_64`), next to the 32-bit one.
- `gametypes.txt` accepts `linux64_*` keys and a `vfuncs_linux64` section, read first by the 64-bit plugin (optional:
  none is needed today, the offsets are the same in 32 and 64 bits).
- `cfg/mani_skins.cfg` and `cfg/mani_quake_sounds.cfg` (Mani's own files from the skins and quake sounds packs), which
  `mani_server.cfg` executes but the plugin package did not contain.
- Reproducible build: `Makefile`, `build.sh` (AlliedModders' build container), `tools/package.sh`.
- `tools/vtable.py` (reads a game vtable, 32 or 64-bit) and `tools/mani_verify.sp` (test plugin).

### Fixed

- Loading: `.vdf` files give the full file name of the plugin (the engine no longer adds `_i486`).
- `gametypes.txt`: 19 virtual function offsets updated for today's `CCSPlayer` and weapons, `spawn_point_control`
  (`LevelInit`) 2 → 3, game rules read from the `g_pGameRules` symbol.
- Empty map lists in the admin menus and votes: `custom/mani_maplist/` filled with the stock maps, and map names are
  checked as `maps/<name>.bsp` (`IVEngineServer::IsMapValid` of the current SDK).
- Crash of `ma_restrict` (and of the other weapon commands) when a weapon is missing from the game's weapon list.
- 64-bit: ELF64 symbol tables, member function pointers with a zeroed `this` adjustment, vtables read as pointers in
  `ma_vfuncs` / `ma_autovfunc`, weapon info offsets (name and price), address sorting without truncation.
- Builds with a current compiler and the current SDK (C++11 `make_pair`, `ISERVERPLUGINCALLBACKS004`, no modified SDK).

### Changed

- Version `Mani Admin Plugin 2026 V1.3.0` (`mani_admin_plugin_version` = `1.3.0 VSP`).
- Out-of-date warnings for `gametypes.txt` and `english.cfg` point to this repository (mani-admin-plugin.com is gone).
- `language/english.cfg` of 1.2.23 (adds texts of the 1.2.23 code).
- Console output always uses `Msg()`: the engine's `ConMsg` was found by decoding machine code that changed.
- The `name Flower` examples of `cexeclist_*.txt` are commented out: clients ignore `name` sent by a server.

### Removed

- Windows binaries and project files, Metamod variant (the server plugin does the same and loads next to Metamod).
- Reserved slots "fill slot" detours (their engine functions no longer exist): built out with `MANI_NO_DETOURS`.

## 1.2.22.15 — 2013

Last release of Mani Admin Plugin for CS:S, by Mani.
