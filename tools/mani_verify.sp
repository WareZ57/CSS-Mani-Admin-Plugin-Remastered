// mani_verify : prints the real state of every player, to check Mani Admin Plugin commands (test only)
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#pragma newdecls required

public Plugin myinfo = { name = "Mani verify", author = "test", description = "Player state for Mani tests" };

public void OnPluginStart()
{
    RegServerCmd("mv_status", Cmd_Status, "Real state of every player");
    RegServerCmd("mv_say", Cmd_Say, "mv_say <name> <text>: the player says text in chat");
}

public Action Cmd_Status(int args)
{
    char name[32], weapons[192], cls[32];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) < 1)
            continue;
        GetClientName(i, name, sizeof(name));
        float pos[3];
        GetClientAbsOrigin(i, pos);
        weapons[0] = '\0';
        for (int s = 0; s < 5; s++)
        {
            int w = GetPlayerWeaponSlot(i, s);
            if (w > 0)
            {
                GetEntityClassname(w, cls, sizeof(cls));
                Format(weapons, sizeof(weapons), "%s%s ", weapons, cls[7]);
            }
        }
        int r, g, b, a;
        GetEntityRenderColor(i, r, g, b, a);
        bool alive = IsPlayerAlive(i);
        PrintToServer("%2d %-10s t%d %s hp%d ap%d $%d pos(%.0f %.0f %.0f) move%d spd%.2f grav%.2f render%d/%d rgba(%d,%d,%d,%d) fire%d frags%d [%s]",
            i, name, GetClientTeam(i), alive ? "A" : "D", alive ? GetClientHealth(i) : 0, GetEntProp(i, Prop_Send, "m_ArmorValue"),
            GetEntProp(i, Prop_Send, "m_iAccount"), pos[0], pos[1], pos[2], view_as<int>(GetEntityMoveType(i)),
            GetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue"), GetEntityGravity(i), view_as<int>(GetEntityRenderMode(i)),
            view_as<int>(GetEntityRenderFx(i)), r, g, b, a, (GetEntityFlags(i) & FL_ONFIRE) ? 1 : 0, GetClientFrags(i), weapons);
    }
    return Plugin_Handled;
}

public Action Cmd_Say(int args)
{
    char name[64], text[192];
    GetCmdArg(1, name, sizeof(name));
    GetCmdArg(2, text, sizeof(text));
    int target = FindTarget(0, name, false, false);
    if (target > 0)
        FakeClientCommand(target, "say %s", text);
    return Plugin_Handled;
}
