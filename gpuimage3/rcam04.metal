
#include <metal_stdlib>

#ifndef OPERATIONSHADERTYPES_H
#define OPERATIONSHADERTYPES_H


struct SingleInputVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
};

#endif

using namespace metal;

#include "RCUtils.h"




typedef struct
{
    float time;
    float filterIntensity;
    float audioLevel;
    float filterVariation;
} RCam04Uniform;


fragment half4 rcam04Fragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                constant RCam04Uniform& uniform [[ buffer(1) ]])
{
    
    constexpr sampler quadSampler;
    float2 p = 2.0 * fragmentInput.textureCoordinate.xy - 1;
    p = p / (1 + uniform.audioLevel);
//    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    float time = uniform.time*.15;

    float3 light1 = float3(  0.577, 0.577, -0.577 );
    float3 light2 = float3( -0.707, 0.000,  0.707 );


    float r = 1.3+0.1*cos(.29*time);
    float3  ro = float3( r*cos(.33*time), 0.8*r*sin(.37*time), r*sin(.31*time) );
    float3  ta = float3(0.0,0.1,0.0);
    float cr = 0.5*cos(0.1*time);

    float fov = 1.5;
    float3 cw = normalize(ta-ro);
    float3 cp = float3(sin(cr), cos(cr),0.0);
    float3 cu = normalize(cross(cw,cp));
    float3 cv = normalize(cross(cu,cw));
    float3 rd = normalize( p.x*cu + p.y*cv + fov*cw );


    float3 cc = float3( 0.9*cos(3.9+1.2*time)-.3, 0.8*cos(2.5+1.1*time), 0.8*cos(3.4+1.3*time) );
    if( length(cc)<0.50 ) cc=0.50*normalize(cc);
    if( length(cc)>0.95 ) cc=0.95*normalize(cc);

    float3 col;
    float4 tra;
    float3 tra1;
    float t = intersect( ro, rd, tra, fov, cc  , uniform.filterIntensity);
    if( t<0.0 )
    {
        col = 1.3*float3(0.8,.95,1.0)*(0.7+0.3*rd.y);
        col += float3(0.8,0.7,0.5)*pow( clamp(dot(rd,light1),0.0,1.0), 32.0 );
    }
    else
    {
        float3 pos = ro + t*rd;
        float3 nor = calcNormal( pos, t, fov, cc , uniform.filterIntensity);
        float3 hal = normalize( light1-rd);
        float3 ref = reflect( rd, nor );
        
        col = float3(1.0,1.0,1.0)*0.3;
        col = mix( col, float3(0.7,0.3,0.3), sqrt(tra.x) );
        col = mix( col, float3(1.0,0.5,0.2), sqrt(tra.y) );
        col = mix( col, float3(1.0,1.0,1.0), tra.z );
        col *= 0.4;
        
        
        float dif1 = clamp( dot( light1, nor ), 0.0, 1.0 );
        float dif2 = clamp( 0.5 + 0.5*dot( light2, nor ), 0.0, 1.0 );
        float occ = clamp(1.2*tra.w-0.6,0.0,1.0);
        float sha = softshadow( pos,light1, 0.0001, 32.0, cc , uniform.filterIntensity );
        float fre = 0.04 + 0.96*pow( clamp(1.0-dot(-rd,nor),0.0,1.0), 5.0 );
        float spe = pow( clamp(dot(nor,hal),0.0,1.0), 12.0 ) * dif1 * fre*8.0;
        
        float3 lin  = 1.0*float3(0.15,0.20,0.23)*(0.6+0.4*nor.y)*(0.1+0.9*occ);
             lin += 4.0*float3(1.00,0.90,0.60)*dif1*sha;
             lin += 4.0*float3(0.14,0.14,0.14)*dif2*occ;
             lin += 2.0*float3(1.00,1.00,1.00)*spe*sha * occ;
             lin += 0.3*float3(0.20,0.30,0.40)*(0.02+0.98*occ);
        col *= lin;
        col += spe*1.0*occ*sha;
        tra1 += lin;
    }

    col = sqrt( col );

//    fragColor = vec4( col, 1.0 )
    
    
    
    half4 white = half4(1.0);
    half d = fragmentInput.textureCoordinate.y * 0.0 + 0.2;
    
    half4 color = inputTexture.sample(quadSampler, float2(tra.xy));
    color = (color - d * white) / (1.0 - d);
    
    
    
    
    return inputTexture.sample(quadSampler,float2(tra.xy) );

    //return half4( tra );

}
