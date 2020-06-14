
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




typedef struct
{
    float time;
    float filterIntensity;
    float audioLevel;
} RCam05Uniform;




fragment half4 rcam05Fragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                constant RCam05Uniform& uniform [[ buffer(1) ]])
{
    
    float2 textureCoordinateToUse = float2(fragmentInput.textureCoordinate.x, ((fragmentInput.textureCoordinate.y - 0.4) * 3.0) + 0.4 + uniform.audioLevel);
    float dist = distance(0.4 + uniform.audioLevel, textureCoordinateToUse);
    textureCoordinateToUse = fragmentInput.textureCoordinate;
    
    
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, textureCoordinateToUse);
//    if (dist < 0.25 + uniform.filterIntensity)
//    {
//        textureCoordinateToUse -= 0.9;
//        float percent = 1.0 - (((0.25 + uniform.filterIntensity  * uniform.audioLevel) - dist) / (0.25 + uniform.filterIntensity)) * 0.5;
//        percent = percent * percent;
//
//        textureCoordinateToUse = textureCoordinateToUse * percent;
//        textureCoordinateToUse += 0.4;
//    }
//
//    if (dist < 0.35 + uniform.filterIntensity)
//    {
//        textureCoordinateToUse -= 0.4;
//        float percent = 1.0 - (((0.25 + uniform.filterIntensity) - dist) / (0.25 + uniform.filterIntensity/ uniform.audioLevel)) * 0.5;
//        percent = percent * percent;
//
//        textureCoordinateToUse = textureCoordinateToUse * percent;
//        textureCoordinateToUse += 0.4 ;
//    }
//
//    if (dist < 0.55 + uniform.filterIntensity)
//    {
//        textureCoordinateToUse -= 0.4;
//        float percent = 1.0 - (((0.25 + uniform.filterIntensity) - dist) / (0.25 + uniform.filterIntensity)) * 0.5;
//        percent = percent * percent;
//
//        textureCoordinateToUse = textureCoordinateToUse * percent;
//        textureCoordinateToUse += 0.4 + uniform.audioLevel;
//        textureCoordinateToUse.x += uniform.time / M_PI_F;
//    }
//
    
    
//    if (dist > 0.80 + uniform.filterIntensity)
//    {
    
    
//        textureCoordinateToUse -= 0.4;
//        float percent = 1.0 - (((0.25 + uniform.filterIntensity) - dist) / (0.25 + uniform.filterIntensity)) * 0.5;
//        percent = percent * percent;
//
//        textureCoordinateToUse = textureCoordinateToUse * percent;
//        textureCoordinateToUse /= 0.4 + uniform.audioLevel;
//        textureCoordinateToUse.y /= uniform.time / M_PI_F * color.y;
//
    
    
    //  }
    
    float2 uv = -1. + 2. * textureCoordinateToUse;
    uv  = (0.5 - uv / 2.0);
    float4 col = float4(
        abs(sin(cos(uniform.time+3.*uv.y)*2.*uv.x+uniform.time)),
        abs(cos(sin(uniform.time+2.*uv.x)*3.*uv.y+uniform.time)),
        uniform.filterIntensity * 1100.,
        1.0);
//    constexpr sampler quadSampler(mag_filter::linear, min_filter::linear);
    return inputTexture.sample(quadSampler, col.xy);

}


//({radius = 0.25})()
//({scale = 0.5})()
//({center = Position.center})()




