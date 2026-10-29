// Access to the private ConVar fields Mani used to reach through its own modified copy of the SDK
// (standard trick: explicit template instantiation may name private members)
#pragma once
#include "convar.h"

template <typename Tag, typename Tag::type Member> struct ManiPrivateAccess
{
	friend typename Tag::type ManiGetMember(Tag) { return Member; }
};

struct ManiConCommandBaseFlags { typedef int ConCommandBase::*type; friend type ManiGetMember(ManiConCommandBaseFlags); };
template struct ManiPrivateAccess<ManiConCommandBaseFlags, &ConCommandBase::m_nFlags>;

struct ManiConVarChangeCallback { typedef FnChangeCallback_t ConVar::*type; friend type ManiGetMember(ManiConVarChangeCallback); };
template struct ManiPrivateAccess<ManiConVarChangeCallback, &ConVar::m_fnChangeCallback>;

#define MANI_CVAR_FLAGS(cvar)		((cvar)->*ManiGetMember(ManiConCommandBaseFlags()))
#define MANI_CVAR_CALLBACK(cvar)	((cvar)->*ManiGetMember(ManiConVarChangeCallback()))
