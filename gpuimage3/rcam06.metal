
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

//float cosh(float val);


typedef struct
{
    float time;
    float filterIntensity;
    float audioLevel;
} RCam06Uniform;


float2 bezier(float2 p0, float2 p1, float2 p2, float2 p3, float t) {
  float one_minus_t = 1. - t;
  return one_minus_t * one_minus_t * one_minus_t * p0 +
    3. * one_minus_t * one_minus_t * t * p1 +
    3. * one_minus_t * t * t * p2 +
    t * t * t * p3;
}

// This one animates t, using control points p1 and p2.
// It is very similar to CSS based cubic-bezier timing funciton.
float bease(float t, float2 p1, float2 p2) {
  float2 p0 = float2(0.);
  float2 p3 = float2(1.);
  float2 res = bezier(p0, p1, p2, p3, t);
  return res.y;
}

// Produces a uniform value between 0 and 1 over `framesCount` frames
//float timef(float framesCount) {
//  return mod(iFrame,framesCount)/framesCount;
//}

// Not sure if I want to keep this.
float bease(float t) {
  return bease(t, float2(0.42, 0), float2(1));
}


float f_cosh(float val) {
  float tmp = exp(val);
  return (tmp + 1.0 / tmp) / 2.0;
}
 
float tanh(float val) {
  float tmp = exp(val);
  return (tmp - 1.0 / tmp) / (tmp + 1.0 / tmp);
}
 
float f_sinh(float val) {
  float tmp = exp(val);
  return (tmp - 1.0 / tmp) / 2.0;
}

float2 cosh(float2 val) {
  float2 tmp = exp(val);
  return(tmp + 1.0 / tmp) / 2.0;
}
 
float2 tanh(float2 val) {
  float2 tmp = exp(val);
  return (tmp - 1.0 / tmp) / (tmp + 1.0 / tmp);
}
 
float2 sinh(float2 val) {
  float2 tmp = exp(val);
  return (tmp - 1.0 / tmp) / 2.0;
}

float2 c_one() { return float2(1., 0.); }
float2 c_i() { return float2(0., 1.); }

float arg(float2 c) {
  return atan2(c.y, c.x);
}

float2 c_conj(float2 c) {
  return float2(c.x, -c.y);
}

float2 c_from_polar(float r, float theta) {
  return float2(r * cos(theta), r * sin(theta));
}

float2 c_to_polar(float2 c) {
  return float2(length(c), atan2(c.y, c.x));
}

/// Computes `e^(c)`, where `e` is the base of the natural logarithm.
float2 c_exp(float2 c) {
  return c_from_polar(exp(c.x), c.y);
}


/// Raises a floating point number to the complex power `c`.
float2 c_exp(float base, float2 c) {
  return c_from_polar(pow(base, c.x), c.y * log(base));
}

/// Computes the principal value of natural logarithm of `c`.
float2 c_ln(float2 c) {
  float2 polar = c_to_polar(c);
  return float2(log(polar.x), polar.y);
}

/// Returns the logarithm of `c` with respect to an arbitrary base.
float2 c_log(float2 c, float base) {
  float2 polar = c_to_polar(c);
  return float2(log(polar.r), polar.y) / log(base);
}

float2 c_sqrt(float2 c) {
  float2 p = c_to_polar(c);
  return c_from_polar(sqrt(p.x), p.y/2.);
}

/// Raises `c` to a floating point power `e`.
float2 c_pow(float2 c, float e) {
  float2 p = c_to_polar(c);
  return c_from_polar(pow(p.x, e), p.y*e);
}

/// Raises `c` to a complex power `e`.
float2 c_pow(float2 c, float2 e) {
  float2 polar = c_to_polar(c);
  return c_from_polar(
     pow(polar.x, e.x) * exp(-e.y * polar.y),
     e.x * polar.y + e.y * log(polar.x)
  );
}

float2 c_mul(float2 self, float2 other) {
    return float2(self.x * other.x - self.y * other.y,
                self.x * other.y + self.y * other.x);
}

float2 c_div(float2 self, float2 other) {
    float norm = length(other);
    return float2(self.x * other.x + self.y * other.y,
                self.y * other.x - self.x * other.y)/(norm * norm);
}

float2 c_sin(float2 c) {
  return float2(sin(c.x) * f_cosh(c.y), cos(c.x) * sinh(c.y));
}

float2 c_cos(float2 c) {
  // formula: cos(a + bi) = cos(a)cosh(b) - i*sin(a)sinh(b)
  return float2(cos(c.x) * f_cosh(c.y), -sin(c.x) * sinh(c.y));
}

float2 c_tan(float2 c) {
  float2 c2 = 2. * c;
  return float2(sin(c2.x), f_sinh(c2.y))/(cos(c2.x) + f_cosh(c2.y));
}

//float2 c_atan(float2 c) {
//  // formula: arctan(z) = (ln(1+iz) - ln(1-iz))/(2i)
//  float2 i = c_i();
//  float2 one = c_one();
//  float2 two = one + one;
//  if (c == i) {
//    return float2(0., 1./0.0);
//  } else if (c == -i) {
//    return float2(0., -1./0.0);
//  }
//
//  return c_div(
//    c_ln(one + c_mul(i, c)) - c_ln(one - c_mul(i, c)),
//    c_mul(two, i)
//  );
//}

float2 c_asin(float2 c) {
 // formula: arcsin(z) = -i ln(sqrt(1-z^2) + iz)
  float2 i = c_i(); float2 one = c_one();
  return c_mul(-i, c_ln(
    c_sqrt(c_one() - c_mul(c, c)) + c_mul(i, c)
  ));
}

float2 c_acos(float2 c) {
  // formula: arccos(z) = -i ln(i sqrt(1-z^2) + z)
  float2 i = c_i();

  return c_mul(-i, c_ln(
    c_mul(i, c_sqrt(c_one() - c_mul(c, c))) + c
  ));
}

float2 c_sinh(float2 c) {
  return float2(sinh(c.x) * cos(c.y), cosh(c.x) * sin(c.y));
}

float2 c_cosh(float2 c) {
  return float2(cosh(c.x) * cos(c.y), sinh(c.x) * sin(c.y));
}

float2 c_tanh(float2 c) {
  float2 c2 = 2. * c;
  return float2(sinh(c2.x), sin(c2.y))/(cosh(c2.x) + cos(c2.y));
}

float2 c_asinh(float2 c) {
  // formula: arcsinh(z) = ln(z + sqrt(1+z^2))
  float2 one = c_one();
  return c_ln(c + c_sqrt(one + c_mul(c, c)));
}

float2 c_acosh(float2 c) {
  // formula: arccosh(z) = 2 ln(sqrt((z+1)/2) + sqrt((z-1)/2))
  float2 one = c_one();
  float2 two = one + one;
  return c_mul(two,
      c_ln(
        c_sqrt(c_div((c + one), two)) + c_sqrt(c_div((c - one), two))
      ));
}

//float2 c_atanh(float2 c) {
//  // formula: arctanh(z) = (ln(1+z) - ln(1-z))/2
//  float2 one = c_one();
//  float2 two = one + one;
//  if (c == one) {
//      return float2(1./0., float2(0.));
//  } else if (c == -one) {
//      return float2(-1./0., float2(0.));
//  }
//  return c_div(c_ln(one + c) - c_ln(one - c), two);
//}

// Attempts to identify the gaussian integer whose product with `modulus`
// is closest to `c`
float2 c_rem(float2 c, float2 modulus) {
  float2 c0 = c_div(c, modulus);
  // This is the gaussian integer corresponding to the true ratio
  // rounded towards zero.
  float2 c1 = float2(c0.x - fmod(c0.x, 1.), c0.y - fmod(c0.y, 1.));
  return c - c_mul(modulus, c1);
}

float2 c_inv(float2 c) {
  float norm = length(c);
    return float2(c.x, -c.y) / (norm * norm);
}









//float2 c_conj(float2 c) {
//  return float2(c.x, -c.y);
//}

//float2 c_mul(float2 self, float2 other) {
//    return float2(self.x * other.x - self.y * other.y,
//                self.x * other.y + self.y * other.x);
//}

//float2 c_inv(float2 c) {
//  float norm = length(c);
//    return float2(c.x, -c.y) / (norm * norm);
//}
//
//float2 c_from_polar(float r, float theta) {
//  return float2(r * cos(theta), r * sin(theta));
//}

//float2 c_exp(float base, float2 c) {
//  return c_from_polar(pow(base, c.x), c.y * log(base));
//}
//
//float2 c_exp(float2 c) {
//  return c_from_polar(exp(c.x), c.y);
//}


// other goodies: c_Ln
float4 get_color1(float2 p, float2 change, float timeSinCos) {
  float t = 0.;
  float2 z = p;
  float2 c = float2(0.53887, 0.52014);

  for(int i = 0; i < 32; ++i) {
    if (length(z) > 4.) break;
    z = c_mul(z, c_exp(z)) + change;
    t = float(i);
  }

  return float4(length(z) * t * float3(1./64., 1./32. * timeSinCos, 1./16.), 1.0);
}

float4 get_color(float2 p) {
  float t = 0.;
  float2 z = float2(1.);
  float2 c = p;

  for(int i = 0; i < 32; ++i) {
    if (length(z) > 2.) break;
    z = c_inv(c_mul(z, c_conj(z))) + c;
    t = float(i);
  }

  return float4(length(tan(z)) * t * float3(1./64., 1./32., 1./16.), 1.0);
}

fragment half4 rcam06Fragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                constant RCam06Uniform& uniform [[ buffer(1) ]])
{
    
//    float2 textureCoordinateToUse = float2(fragmentInput.textureCoordinate.x, ((fragmentInput.textureCoordinate.y - 0.4) * 3.0) + 0.4 + uniform.audioLevel);
//    float dist = distance(0.4 + uniform.audioLevel, textureCoordinateToUse);
//    textureCoordinateToUse = fragmentInput.textureCoordinate;
    
    
    
    constexpr sampler samp(coord::normalized,
    address::clamp_to_edge,
    filter::nearest);
    
//    half4 fractIn = half4(get_color1(float2(0.5 - 2.0 * textureCoordinateToUse.xy), float2(uniform.filterIntensity, uniform.audioLevel / 10.0), abs(sin(cos(uniform.time+3.*textureCoordinateToUse.y)*2.*textureCoordinateToUse.x+uniform.time))));

    half4 color1 = inputTexture.sample(samp, fragmentInput.textureCoordinate.xy);

    
    
    half4 vcolor =  half4(get_color1(float2(0.5 - 2.0 * fragmentInput.textureCoordinate.xy), float2(uniform.filterIntensity, uniform.filterIntensity / 10.0), 1.0));
    
    half4 color = inputTexture.sample(samp, float2(vcolor.xy));
    return color;

}


//({radius = 0.25})()
//({scale = 0.5})()
//({center = Position.center})()




