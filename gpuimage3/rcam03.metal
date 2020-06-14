
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





// WATER
// ===================================================


constant float PI = 3.1415926535897932;

//speed
constant float intense1 = 0.2;

constant float speed1 = 0.2;
constant float speed_x1 = 0.2;
constant float speed_y1 = 0.2;

// refraction
constant float emboss1 = 0.80;
constant float intensity1 = 1.4;
constant int steps1 = 18;
constant float frequency1 = 6.0;
constant int angle1 = 2; // better when a prime

// reflection
constant float delta1 = 60.;

constant float reflectionCutOff1 = 0.012;
constant float reflectionIntence1 = 200000.;

float col1(float2 coord,float time, float speed, float intens1, float soundLevel);
// ===================================================


float col1(float2 coord,float time, float speed, float intens1, float soundLevel)
{
    float delta_theta = 2.0 * PI / float(angle1 + (intens1 / 45.0 ));
    float col = 0.0;
    float theta = 0.0;
    for (int i = 0; i < steps1; i++)
    {
        float2 adjc = coord;
        theta = delta_theta*float(i);
        adjc.x += cos(theta)*time*speed + time * speed_x1;
        adjc.y -= sin(theta)*time*speed - time * speed_y1;
        col = col + cos( (adjc.x*cos(theta) - adjc.y*sin(theta))*frequency1)*intensity1 * (soundLevel * 10.0);
    }
    
    return cos(col);
}





typedef struct
{
    float time;
    float filterIntensity;
    float audioLevel;
    float filterVariation;
} RCam03Uniform;


fragment half4 rcam03Fragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                constant RCam03Uniform& uniform [[ buffer(1) ]])
{
    
    
    
    
    
    
    constexpr sampler s(coord::normalized,
                        address::repeat,
                        filter::nearest);
    
    float time = uniform.time *  1.3;
    
    int width = inputTexture.get_width();
    int height = inputTexture.get_height();
    
//    float2 p = float2(fragmentInput.textureCoordinate.xy) / float2(width, height);
//
//    p =  float2(2.0 * fragmentInput.textureCoordinate.x, 1.0 - (2.0 * fragmentInput.textureCoordinate.y) ); // float2(p.x, 1 - p.y);
    
    float2 p = fragmentInput.textureCoordinate.xy - 1.0;
   // p = float2(p.x, 1 - p.y);

    
    float2 c1 = p, c2 = p;
    float cc1 = col1(c1, time, speed1, uniform.filterIntensity, uniform.audioLevel);
    
    c2.x += width/delta1;
    float dx = emboss1*(cc1-col1(c2 ,time, speed1, uniform.filterIntensity, uniform.audioLevel))/delta1;
    
    
    c2.x = p.x;
    c2.y += height/delta1;
    float dy = emboss1*(cc1-col1(c2,time, speed1, uniform.filterIntensity, uniform.audioLevel))/delta1;
    
    
    
    c1.x *= dx*2.;
    c1.y = -(c1.y+dy*2.);
    
    float alpha = 1. +  dx * dy * intense1;
    
    float ddx = dx - reflectionCutOff1;
    float ddy = dy - reflectionCutOff1   + 0.2;
    if (ddx > 0. && ddy > 0.)
        alpha = pow(alpha, ddx*ddy*reflectionIntence1);
    
    

    constexpr sampler quadSampler;
    
    
    
    half4 Hwhite = half4(1.0);
    
    half Hd = fragmentInput.textureCoordinate.y * 0.0 + 0.2;
    
    half4 Hcolor = inputTexture.sample(quadSampler, c1);
    Hcolor = (Hcolor - Hd * Hwhite) / (1.0 - Hd);
    
    

    return inputTexture.sample(quadSampler, float2(Hcolor.xy));

}
