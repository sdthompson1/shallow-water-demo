/*
 * FILE:
 *   settings.hpp
 *
 * PURPOSE:
 *   Abstract interface for rendering and simulation settings.
 *
 * AUTHOR:
 *   Stephen Thompson <stephen@solarflare.org.uk>
 *
 * CREATED:
 *   24-Oct-2011
 *
 * COPYRIGHT:
 *   Copyright (C) 2012, Stephen Thompson. All rights reserved.
 *
 */

#ifndef SETTINGS_HPP
#define SETTINGS_HPP

#include <string>
#include <vector>

enum SettingType {
    S_NULL,
    S_NEW_TAB,
    S_LABEL,
    S_SLIDER,
    S_SLIDER_INT,
    S_SLIDER_MULT_4,
    S_CHECKBOX,
    S_LEFT_MOUSE_DROPDOWN
};

enum ResetType {
    R_NONE,
    R_TERRAIN,
    R_MESH,     // remesh, no water
    R_VALLEY,   // remesh, setup water in valley
    R_SEA,      // remesh, fill to sea level
    R_SQUARE    // remesh, fill in a square in the middle
};

enum LeftMouseSettings {
    LM_ADD_WATER,
    LM_REMOVE_WATER,
    LM_STIR_WATER,
    LM_RAISE_TERRAIN,
    LM_LOWER_TERRAIN
};

struct Setting {
    const char * name;
    const char * unit;
    SettingType type;
    ResetType reset_type;
    double min;
    double max;
    double value;
};

// global array of settings, 'null terminated'
extern Setting g_settings[];

// flag to communicate when the settings have changed
extern ResetType g_reset_type;

// helper functions
float GetSetting(const char * name);
inline float GetSetting(const std::string &s) { return GetSetting(s.c_str()); }
int GetIntSetting(const char *name);

void SetSetting(const char *name, float new_value);
inline void SetSettingD(const char *name, double val) { SetSetting(name, float(val)); }

#endif
