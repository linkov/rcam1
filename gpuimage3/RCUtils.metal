//
//  RCUtils.metal
//  GPUImage
//
//  Created by Alex Linkov on 10/5/20.
//  Copyright © 2020 Red Queen Coder, LLC. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


#include <metal_stdlib>

using namespace metal;

#include "RCUtils.h"


// MARK: Fractal 1
float2 isphere( float4 sph, float3 ro, float3 rd )
{
    float3 oc = ro - sph.xyz;
    
    float b = dot(oc,rd);
    float c = dot(oc,oc) - sph.w*sph.w;
    float h = b*b - c;
    if( h<0.0 ) return float2(-1.0);
    h = sqrt( h );
    return -b + float2(-h,h);
}

float map( float3 p, float3 c, float4 &resColor , float intesity)
{
    float3 z = p;
    float m = dot(z,z);

    float4 trap = float4(abs(z),m);
    float dz = 1.0;
    
    float rIntense = intesity * 10.0;
    
    if (rIntense < 2.0) {
        rIntense = 2.0;
    }
    
    for( int i=0; i<4; i++ )
    {
        dz = rIntense*pow(m,3.5)*dz;
        
#if 0
        float x1 = z.x; float x2 = x1*x1; float x4 = x2*x2;
        float y1 = z.y; float y2 = y1*y1; float y4 = y2*y2;
        float z1 = z.z; float z2 = z1*z1; float z4 = z2*z2;

        float k3 = x2 + z2;
        float k2 = inversesqrt( k3*k3*k3*k3*k3*k3*k3 );
        float k1 = x4 + y4 + z4 - 6.0*y2*z2 - 6.0*x2*y2 + 2.0*z2*x2;
        float k4 = x2 - y2 + z2;

        z.x = c.x +  64.0*x1*y1*z1*(x2-z2)*k4*(x4-6.0*x2*z2+z4)*k1*k2;
        z.y = c.y + -16.0*y2*k3*k4*k4 + k1*k1;
        z.z = c.z +  -8.0*y1*k4*(x4*x4 - 28.0*x4*x2*z2 + 70.0*x4*z4 - 28.0*x2*z2*z4 + z4*z4)*k1*k2;
#else
        
        float r = length(z);
        float b = 8.0*acos( clamp(z.y/r, -1.0, 1.0));
        float a = 8.0*atan2( z.x, z.z );
        z = c + pow(r,8.0) * float3( sin(b)*sin(a), cos(b), sin(b)*cos(a) );
#endif
        
        trap = min( trap, float4(abs(z),m) );

        m = dot(z,z);
        if( m > 2.0 )
            break;
    }

    resColor = trap;

    return 0.25*log(m)*sqrt(m)/dz;
}

float intersect( float3 ro, float3 rd, float4 &rescol, float fov, float3 c  , float intensity)
{
    float res = -1.0;

    // bounding volume
    float2 dis = isphere( float4( 0.0, 0.0, 0.0, 1.25 ), ro, rd );
    if( dis.y<0.0 )
        return -1.0;
    dis.x = max( dis.x, 0.0 );

    float4 trap;

    // raymarch
    float fovfactor = 1.0/sqrt(1.0+fov*fov);
    float t = dis.x;
    for( int i=0; i<128; i++  )
    {
        float3 p = ro + rd*t;

        float surface = clamp( 0.0015*t*fovfactor, 0.0001, 0.1 );

        float dt = map( p, c, trap , intensity);
        if( t>dis.y || dt<surface ) break;

        t += dt;
    }
    
    
    if( t<dis.y )
    {
        rescol = trap;
        res = t;
    }

    return res;
}

// MARK: Fractal 2

float3 nor(float3 pos, float time )
{
    float3 eps = float3(0.001,0.0,0.0);
    return normalize( float3(
           f(pos+eps.xyy, time).x - f(pos-eps.xyy, time).x,
           f(pos+eps.yxy, time).x - f(pos-eps.yxy, time).x,
           f(pos+eps.yyx, time).x - f(pos-eps.yyx, time).x ) );
}



float3 mb(float3 p, float time) {
    p.xyz = p.xzy;
    float3 z = p;
    float3 dz= float3(0.0);
    float power = 4.0;
    float r, theta, phi;
    float dr = 2.0;
    
    float t0 = 1.0;
    for(int i = 0; i < 7; ++i) {
        r = length(z);
        if(r > 2.0) continue;
        theta = atan(z.y / z.x);
        #ifdef phase_shift_on
        phi = asin(z.z / r) + iTime*0.1;
        #else
        phi = asin(z.z / r);
        #endif
        
        dr = pow(r, power - 1.0) * dr * power + 1.0;
    
        r = pow(r, power);
        theta = theta * power;
        phi = phi * power;
        
        z = r * float3(cos(theta)*cos(phi), sin(theta)*cos(phi), sin(phi)) + p;
        t0 = min(t0, r);
    }
    return float3(0.5 * log(r) * r / dr, t0, 0.0);
}

float3 intersect2(float3 ro, float3 rd, float time, float intensity )
{
    float t = 1.0;
    float res_t = 0.0;
    float res_d = 1000.0;
    float3 c, res_c;
    float max_error = 1000.0;
    float d = 1.0;
    float pd = 100.0;
    float os = 0.0;
    float step = 0.0;
    float error = 1000.0;
    float pixel_size = 0.0;
    
    
    for( int i=0; i<(intensity * 100.0); i++ )
    {

        
        c = f(ro + rd*t, time);
            d = c.x;

            if(d > os)
            {
                os = 0.4 * d*d/pd;
                step = d + os;
                pd = d;
            }
            else
            {
                step =-os; os = 0.0; pd = 100.0; d = 1.0;
            }

            error = d / t;

            if(error < max_error)
            {
                max_error = error;
                res_t = t;
                res_c = c;
            }
        
            t += step;
    

    }
    if( t>20.0/* || max_error > pixel_size*/ ) res_t=-1.0;
    return float3(res_t, res_c.y, res_c.z);
}

float3 f(float3 p, float time ) {
    ry(p, time*0.2);
    return mb(p, time);
}

void ry(float3 &p, float a) {
    float c,s; float3 q = p;
     c = cos(a); s = sin(a);
     p.x = c * q.x + s * q.z;
//     p.z = -s * q.x + c * q.z;
}

float softshadow2(float3 ro, float3 rd, float k, float time ) {
    float akuma=1.0,h=0.0;
    float t = 0.01;
    for(int i=0; i < 50; ++i){
        h=f(ro+rd*t, time).x;
        if(h<0.001)return 0.02;
        akuma=min(akuma, k*h/t);
         t+=clamp(h,0.01,2.0);
    }
    return akuma;
}

float softshadow( float3 ro, float3 rd, float mint, float k, float3 c , float intensity)
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<80; i++ )
    {
        float4 kk;
        float h = map(ro + rd*t, c, kk, intensity);
        res = min( res, k*h/t );
        if( res<0.001 ) break;
        t += clamp( h, 0.002, 0.1 );
    }
    return clamp( res, 0.0, 1.0 );
}

float3 calcNormal( float3 pos, float t, float fovfactor, float3 c, float intensity )
{
    float4 tmp;
    float surface = clamp( 0.3 * 0.0015*t*fovfactor, 0.0001, 0.1 );
    float2 eps = float2( surface, 0.0 );
    return normalize( float3(
                             map(pos+eps.xyy,c,tmp, intensity) - map(pos-eps.xyy,c,tmp, intensity),
                             map(pos+eps.yxy,c,tmp, intensity) - map(pos-eps.yxy,c,tmp, intensity),
           map(pos+eps.yyx,c,tmp, intensity) - map(pos-eps.yyx,c,tmp, intensity) ) );

}
