//
//  RCUtils.h
//  GPUImage
//
//  Created by Alex Linkov on 10/5/20.
//  Copyright © 2020 Red Queen Coder, LLC. All rights reserved.
//

#ifndef RCUtils_h
#define RCUtils_h

#include <metal_stdlib>

using namespace metal;

// MARK: Fractal 1
float map( float3 p, float3 c, float4 &resColor , float intesity);
float2 isphere( float4 sph, float3 ro, float3 rd );
float3 calcNormal( float3 pos, float t, float fovfactor, float3 c, float intensity );
float softshadow( float3 ro, float3 rd, float mint, float k, float3 c , float intensity);
float intersect( float3 ro, float3 rd, float4 &rescol, float fov, float3 c  , float intensity);

// MARK: Fractal 2
float3 intersect2(float3 ro, float3 rd, float time, float intensity );
float softshadow2(float3 ro, float3 rd, float k, float time );
void ry(float3 &p, float a);
float3 f(float3 p, float time);
float3 nor(float3 pos, float time);

#endif /* RCUtils_h */
