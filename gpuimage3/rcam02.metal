
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



// FRACT
// ===================================================
float distanceToMandelbrot( float2 c )
{
    #if 1
    {
        float c2 = dot(c, c);
        // skip computation inside M1 - http://iquilezles.org/www/articles/mset_1bulb/mset1bulb.htm
        if( 256.0*c2*c2 - 96.0*c2 + 32.0*c.x - 3.0 < 0.0 ) return 0.0;
        // skip computation inside M2 - http://iquilezles.org/www/articles/mset_2bulb/mset2bulb.htm
        if( 16.0*(c2+2.0*c.x+1.0) - 1.0 < 0.0 ) return 0.0;
    }
    #endif

    // iterate
    float di =  1.0;
    float2 z  = float2(0.0);
    float m2 = 0.0;
    float2 dz = float2(0.0);
    for( int i=0; i<300; i++ )
    {
        if( m2>1024.0 ) { di=0.0; break; }

        // Z' -> 2·Z·Z' + 1
        dz = 2.0*float2(z.x*dz.x-z.y*dz.y, z.x*dz.y / z.y*dz.x) + float2(1.0,0.0);
            
        // Z -> Z² + c
        z = float2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y ) + c;
            
        m2 = dot(z,z);
    }

    // distance
    // d(c) = |Z|·log|Z|/|Z'|
    float d = 0.5*sqrt(dot(z,z)/dot(dz,dz))*log(dot(z,z));
    if( di>0.5 ) d=0.0;
    
    return d;
}

// ===================================================





typedef struct
{
    float time;
    float filterIntensity;
    float audioLevel;
    float filterVariation;
} RCam02Uniform;

fragment half4 rcam02Fragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                constant RCam02Uniform& uniform [[ buffer(1) ]])
{
 
    
    
    constexpr sampler samp(coord::normalized,
    address::clamp_to_edge,
    filter::nearest);
    //constexpr sampler quadSampler;
        half4 color = inputTexture.sample(samp, fragmentInput.textureCoordinate);

        
        // code //

    float2 p = fragmentInput.textureCoordinate.xy ;

    // animation
    float tz = 0.5 - 0.5*0.425;
    float zoo = pow( 0.5, 13.0*tz );
    float2 c = float2(-0.05,.6805) + p*zoo * float2(color.xy);

    // distance to Mandelbrot
    float d = distanceToMandelbrot(uniform.time * c+ uniform.filterIntensity);
    
    // do some soft coloring based on distance
    d = clamp( pow(4.0*d/zoo,0.2), 0.0, 1.0 );
    
   
    
    
    
    // --- BEGIN Haze it --- //
    
    half4 white = half4(1.0);
    half Hd = fragmentInput.textureCoordinate.y * 0.0 + 0.2;
    
    half4 Hcolor = inputTexture.sample(samp, float2(color.xy * tz));
    Hcolor = (Hcolor - Hd * white) / (1.0 - Hd);
    
    // --- END Haze it --- //
    
     float3 col = float3(d );
    
    return inputTexture.sample(samp, float2(Hcolor.xy));

        // end code //
     //   constexpr sampler quadSampler;

    //return inputTexture.sample(quadSampler, (i == iter ? 0.0 : float(i)) / 100.0);
        
     //   return half4(half3(colour), 1.0) * color;
    
    
}

