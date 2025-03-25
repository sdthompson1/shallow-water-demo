/*
 * FILE:
 *   perlin.hpp
 *
 * PURPOSE:
 *   Simple Perlin noise
 *
 * AUTHOR:
 *   Stephen Thompson <stephen@solarflare.org.uk>
 *
 * CREATED:
 *   25-Oct-2011
 *
 * COPYRIGHT:
 *   Copyright (C) 2012, Stephen Thompson. All rights reserved.
 *
 */

#ifndef PERLIN_HPP
#define PERLIN_HPP

void InitPerlin();

float Perlin(float base_lambda, float persistence, int octaves, float x);
float DPerlinDX(float base_lambda, float persistence, int octaves, float x);

/* 2D perlin noise, not used
float Perlin2(float base_lambda_x, float base_lambda_y, float persistence, int octaves, float x, float y);
*/

#endif
