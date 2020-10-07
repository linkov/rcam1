
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




// void mainImage( out vec4 fragColor, in vec2 fragCoord )
// {
//
// }







typedef struct
{
    float time;
    float filterIntensity;
    float audioLevel;
    float filterVariation;
} RCam044Uniform;


fragment half4 rcam044Fragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                constant RCam044Uniform& uniform [[ buffer(1) ]])
{
    
    constexpr sampler quadSampler;
    
    
    
    
    
    
    //float2 p =
   half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    float time = uniform.time*.15;
    

   // float2 q=inputTexture./fragmentInput.position;
    float2 uv = fragmentInput.textureCoordinate.xy / (1 + uniform.audioLevel * 6.0);
    //uv.x*=fragmentInput.position.x/fragmentInput.position.y;
     
    float pixel_size = 1.0/(fragmentInput.position.x * 3.0);
    // camera
    float stime=0.7+0.3*sin(time*0.4) - uniform.audioLevel;
    float ctime=0.7+0.3*cos(time*0.4) - uniform.audioLevel;

    float3 ta=float3(0.0,0.0,0.0);
    float3 ro = float3(0.0, 3.*stime*ctime, 3.*(1.-stime*ctime));

    float3 cf = normalize(ta-ro);
    float3 cs = normalize(cross(cf,float3(0.0,1.0,0.0)));
    float3 cu = normalize(cross(cs,cf));
    float3 rd = normalize(uv.x*cs + uv.y*cu + 3.0*cf);  // transform from view to world

    float3 sundir = normalize(float3(0.1, 0.8, 0.6));
    float3 sun = float3(1.64, 1.27, 0.99);
    float3 skycolor = float3(0.6, 1.5, 1.0);

    float3 bg = exp(uv.y-2.0)*float3(0.4, 1.6, 1.0);

    float halo=clamp(dot(normalize(float3(-ro.x, -ro.y, -ro.z)), rd), 0.0, 1.0);
    float3 col=bg+float3(1.0,0.8,0.4)*pow(halo,17.0);

    //col=float3(1.0,0.8,0.4);
    float t = 0.0;
    float3 p = ro;
     
    float3 res = intersect2(ro, rd, time, uniform.filterIntensity);
     if(res.x > 0.0){
           p = ro + res.x * rd;
         float3 n = nor(p, time);
         float shadow = softshadow(p, sundir, 10.0, time, time, time);

           float dif = max(0.0, dot(n, sundir));
           float sky = 0.6 + 0.4 * max(0.0, dot(n, float3(0.0, 1.0, 0.0)));
            float bac = max(0.3 + 0.7 * dot(float3(-sundir.x, -1.0, -sundir.z), n), 0.0);
           float spe = max(0.0, pow(clamp(dot(sundir, reflect(rd, n)), 0.0, 1.0), 10.0));

         float3 lin = 4.5 * sun * dif * shadow;
         lin += 0.8 * bac * sun;
         lin += 0.6 * sky * skycolor*shadow;
         lin += 3.0 * spe * shadow;

         res.y = pow(clamp(res.y, 0.0, 1.0), 0.55);
         float3 tc0 = 0.5 + 0.5 * sin(3.0 + 4.2 * res.y + float3(0.0, 0.5, 1.0));
           col = lin *float3(0.9, 0.8, 0.6) *  0.2 * tc0;
            col=mix(col,bg, 1.0-exp(-0.001*res.x*res.x));
    }

    // post
    col=pow(clamp(col,0.0,1.0),float3(0.45));
    col=col*0.6+0.4*col*col*(3.0-2.0*col);  // contrast
    col=mix(col, float3(dot(col, float3(0.33))), -0.5);  // satuation
    //col*=0.5+0.5*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);  // vigneting
    float4 fragColor = float4(col.xyz, smoothstep(0.55, .76, 1.-res.x/5.));
    
    
    
    
    
    
    
    
    return inputTexture.sample(quadSampler,float2(fragColor.xy) );

    //return half4( fragColor );

}
