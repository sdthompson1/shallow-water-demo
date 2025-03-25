/*
 * FILE:
 *   terrain_heightfield.hpp
 *
 * PURPOSE:
 *   Function to compute the terrain heightfield given current
 *   settings
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

#ifndef TERRAIN_HEIGHTFIELD_HPP
#define TERRAIN_HEIGHTFIELD_HPP

#include "boost/scoped_array.hpp"

void UpdateTerrainHeightfield();
float GetTerrainHeight(float x, float y);  // does interpolation / clamping

struct TerrainEntry {
    float B, dBdx, dBdy;
};

struct BottomEntry {
    float BY, BX, BA;
};

// used to initialize the heightfield texture (used by the terrain vertex shader).
// includes ghost zones.
// TODO: this should probably be baked into the terrain mesh instead.
extern boost::scoped_array<TerrainEntry> g_terrain_heightfield;

// used to initialize the "bottom" texture (used for simulation).
extern boost::scoped_array<BottomEntry> g_bottom;


extern float g_inlet_x;

#endif
