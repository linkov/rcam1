
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



// Water 1 //

#define TAU 6.28318530718
#define MAX_ITER 5

// end Water 1 //








typedef struct
{
    float time;
    float filterIntensity;
     float audioLevel;
     float filterVariation;
} RCam01Uniform;

fragment half4 rcam01Fragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                constant RCam01Uniform& uniform [[ buffer(1) ]])
{

        constexpr sampler quadSampler;
      
        float time = uniform.time * .5+23.0;
            // uv should be the 0-1 uv of texture...
        float2 uv = fragmentInput.textureCoordinate.xy;
            

    float2 p = fmod(uv*TAU, TAU )-250.0;


    float2 i = float2(p);
        float c = 1.0;
    float inten = .005;

            for (int n = 0; n < MAX_ITER; n++)
            {
                float t = time * (1.0  - (3.5 / float(n+1)));
                i = p + float2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x))  ;
                c +=  1.0/length(float2( p.x  / (sin(i.x+t)/inten),p.y / (cos(i.y+t)/inten )));
                
               
            }
            c /= float(MAX_ITER);
            c =   1.17  - pow(c, 1.4 - (uniform.filterIntensity * 5.0)) ;
            float3 colour = float3(pow(abs(c), 8.0 ));
            colour = clamp(colour + float3(0.0, 0.35, 0.5), 0.0, 1.0);

            


    //        fragColor = vec4(colour, 1.0);
    //
        
        
        
        // end code //
     //   constexpr sampler quadSampler;

//    // --- BEGIN Haze it --- //
//
//    half4 white = half4(1.0);
//    half d = fragmentInput.textureCoordinate.y * 0.0 + 0.2;
//
//    half4 color = inputTexture.sample(quadSampler, colour.xy);
//    color = (color - d * white) / (1.0 - d);
//
//    // --- END Haze it --- //
//
    return inputTexture.sample(quadSampler, float2(colour.xy));
        
     //   return half4(half3(colour), 1.0) * color;
    
    
}
