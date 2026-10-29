# Mani Admin Plugin for Counter-Strike: Source, Linux, VSP (server plugin, no Metamod needed)
#
#   make ARCH=x86      -> build/x86/mani_admin_plugin_i486.so   (32-bit server, srcds_run)
#   make ARCH=x86_64   -> build/x86_64/mani_admin_plugin_x64.so (64-bit server, srcds_run_64)
#
# Use build.sh: it fetches the SDKs (tools/fetch_deps.sh) and runs this Makefile in AlliedModders' build container.

ARCH ?= x86_64

HL2SDK   = deps/hl2sdk-css
MMSOURCE = deps/mmsource
SH_DIR   = $(MMSOURCE)/core/sourcehook
OBJ_DIR  = build/obj/$(ARCH)

CXX = g++
WARNINGS ?= -w

PLUGIN_FILES = \
	mani_adverts.cpp mani_afk.cpp mani_anti_rejoin.cpp mani_autokickban.cpp mani_automap.cpp \
	mani_chattrigger.cpp mani_client.cpp mani_client_interface.cpp mani_client_sql.cpp \
	mani_client_util.cpp mani_command_control.cpp mani_commands.cpp mani_convar.cpp mani_crontab.cpp \
	mani_css_betting.cpp mani_css_bounty.cpp mani_css_objectives.cpp mani_customeffects.cpp \
	mani_database.cpp mani_delayed_client_command.cpp mani_downloads.cpp mani_effects.cpp mani_file.cpp \
	mani_gametype.cpp mani_ghost.cpp mani_globals.cpp mani_handlebans.cpp mani_help.cpp \
	mani_hlxinterface.cpp mani_keyvalues.cpp mani_language.cpp mani_linuxutils.cpp \
	mani_log_css_stats.cpp mani_log_dods_stats.cpp mani_main.cpp mani_mapadverts.cpp mani_maps.cpp \
	mani_memory.cpp mani_menu.cpp mani_messagemode.cpp mani_mostdestructive.cpp mani_mp_restartgame.cpp \
	mani_mutex.cpp mani_mysql.cpp mani_netidvalid.cpp mani_observer_track.cpp mani_output.cpp \
	mani_panel.cpp mani_parser.cpp mani_ping.cpp mani_player.cpp mani_playerkick.cpp mani_quake.cpp \
	mani_replace.cpp mani_reservedslot.cpp mani_save_scores.cpp mani_sigscan.cpp mani_skins.cpp \
	mani_sounds.cpp mani_spawnpoints.cpp mani_sprayremove.cpp mani_stats.cpp mani_team.cpp \
	mani_team_join.cpp mani_teamkill.cpp mani_timers.cpp mani_trackuser.cpp mani_util.cpp mani_vars.cpp \
	mani_vfuncs.cpp mani_victimstats.cpp mani_voice.cpp mani_vote.cpp mani_warmuptimer.cpp \
	mani_weapon.cpp mrecipientfilter.cpp \
	mani_callback_valve.cpp mani_sourcehook.cpp

# Static hooks only: SourceHook's run-time hook generator is not needed (and does not exist for Linux x86_64)
SH_FILES = sourcehook.cpp sourcehook_impl_chookidman.cpp sourcehook_impl_chookmaninfo.cpp \
           sourcehook_impl_cproto.cpp sourcehook_impl_cvfnptr.cpp

DEMANGLE_FILES = cp-demangle.cpp cp-demint.cpp cplus-dem.cpp safe-ctype.cpp xmalloc.cpp xstrdup.cpp

# Engine codes from hl2sdk-manifests (Metamod's headers test SOURCE_ENGINE against them); CS:S = 6
SE_DEFINES = -DSE_EPISODEONE=1 -DSE_DARKMESSIAH=2 -DSE_ORANGEBOX=3 -DSE_BLOODYGOODTIME=4 -DSE_EYE=5 -DSE_CSS=6 \
             -DSE_HL2DM=7 -DSE_DODS=8 -DSE_SDK2013=9 -DSE_PVKII=10 -DSE_BMS=11 -DSE_TF2=12 -DSE_LEFT4DEAD=13 \
             -DSE_NUCLEARDAWN=14 -DSE_CONTAGION=15 -DSE_LEFT4DEAD2=16 -DSE_ALIENSWARM=17 -DSE_PORTAL2=18 \
             -DSE_BLADE=19 -DSE_INSURGENCY=20 -DSE_DOI=21 -DSE_MCV=22 -DSE_CSGO=23 -DSE_DOTA=24 -DSE_CS2=25 \
             -DSE_MOCK=26 -DSE_DEADLOCK=27

# MANI_NO_DETOURS: the reserved slots "fill slot" detours hook engine functions whose symbols no longer exist
DEFINES = -DGAME_ORANGE -DGAME_CSS -DCSTRIKE_DLL -DNO_HOOK_MALLOC -DNO_MALLOC_OVERRIDE -DMANI_NO_DETOURS \
          -DCOMPILER_GCC -D_LINUX -DLINUX -DPOSIX -DGNUC -DNDEBUG -DSWDS -DSOURCE_ENGINE=6 $(SE_DEFINES) \
          -Dstricmp=strcasecmp -D_stricmp=strcasecmp -D_strnicmp=strncasecmp -Dstrnicmp=strncasecmp \
          -D_snprintf=snprintf -D_vsnprintf=vsnprintf -D_alloca=alloca -Dstrcmpi=strcasecmp \
          -DHAVE_DECL_BASENAME -DARCH=$(ARCH)

INCLUDES = -include src/compat/sdk_compat.h -Isrc -Isrc/demangle -Isrc/jit \
           $(addprefix -I$(HL2SDK)/,public public/engine public/mathlib public/vstdlib public/tier0 public/tier1 \
             public/toolframework public/game/server game/shared game/server common public/steam) \
           -I$(MMSOURCE)/core -I$(SH_DIR)

ifeq ($(ARCH),x86)
  # 32-bit: MySQL client 5.1 shipped with Mani's sources
  OUT       = build/x86/mani_admin_plugin_i486.so
  ARCHFLAGS = -m32 -march=pentium4 -msse2 -mfpmath=sse
  INCLUDES += -Isrc/mysql5.1/linux_32/include
  SDK_LIBS  = $(HL2SDK)/lib/public/linux/tier1_i486.a $(HL2SDK)/lib/public/linux/mathlib_i486.a \
              src/mysql5.1/linux_32/lib/libmysqlclient.a src/mysql5.1/linux_32/lib/libz.a
  SDK_DIR   = $(HL2SDK)/lib/public/linux
else ifeq ($(ARCH),x86_64)
  # 64-bit: no MySQL client (src/compat/nomysql), Mani uses its text files
  OUT       = build/x86_64/mani_admin_plugin_x64.so
  ARCHFLAGS = -m64 -march=core2
  DEFINES  += -DX64BITS -DPLATFORM_64BITS
  INCLUDES += -Isrc/compat/nomysql
  SDK_LIBS  = $(HL2SDK)/lib/public/linux64/tier1.a $(HL2SDK)/lib/public/linux64/mathlib.a
  SDK_DIR   = $(HL2SDK)/lib/public/linux64
else
  $(error ARCH must be x86 or x86_64)
endif

CXXFLAGS = $(ARCHFLAGS) -O2 -fPIC -fvisibility=hidden -std=c++17 -fpermissive -fno-strict-aliasing \
           -fno-exceptions -pipe $(WARNINGS) $(DEFINES) $(INCLUDES)

LDFLAGS = $(ARCHFLAGS) -shared -static-libstdc++ -static-libgcc -Wl,--no-undefined -Wl,-s \
          $(SDK_LIBS) -L$(SDK_DIR) -l:libtier0_srv.so -l:libvstdlib_srv.so -ldl -lm -lpthread

OBJS = $(PLUGIN_FILES:%.cpp=$(OBJ_DIR)/%.o) $(SH_FILES:%.cpp=$(OBJ_DIR)/sh/%.o) \
       $(DEMANGLE_FILES:%.cpp=$(OBJ_DIR)/demangle/%.o)

all: $(OUT)

$(OUT): $(OBJS)
	@mkdir -p $(dir $@)
	$(CXX) -o $@ $(OBJS) $(LDFLAGS)

$(OBJ_DIR)/%.o: src/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(OBJ_DIR)/sh/%.o: $(SH_DIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(OBJ_DIR)/demangle/%.o: src/demangle/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf build

.PHONY: all clean
