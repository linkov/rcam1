
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
    
    
    
//    half4 white = half4(1.0);
//    half d = fragmentInput.textureCoordinate.y * 0.0 + 0.2;
//    
//    half4 color = inputTexture.sample(quadSampler, float2(tra.xy));
//    color = (color - d * white) / (1.0 - d);
    
    
    
    
    return inputTexture.sample(quadSampler, float2(tra.xy) );

    //return half4( tra );

}
