// Sourced from https://gist.github.com/igv/8a77e4eb8276753b54bb94c1c50c317e
//
// Copyright (c) 2015-2020, bacondither
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer
//    in this position and unchanged.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Adaptive sharpen - version LQ-1Pass - 2020-11-14
// Tuned for use post-resize, EXPECTS FULL RANGE GAMMA LIGHT (requires ps >= 3.0)

//!HOOK SCALED
//!BIND HOOKED
//!DESC adaptive-sharpen

//--------------------------------------- Settings ------------------------------------------------

#define curve_height    1.0                  // Main control of sharpening strength [>0]
                                             // 0.3 <-> 2.0 is a reasonable range of values

#define video_level_out false                // True to preserve BTB & WTW (minor summation error)
                                             // Normally it should be set to false

// Defined values under this row are "optimal" DO NOT CHANGE IF YOU DO NOT KNOW WHAT YOU ARE DOING!

#define curveslope      0.5                  // Sharpening curve slope, high edge values

#define L_overshoot     0.003                // Max light overshoot before compression [>0.001]
#define L_compr_low     0.167                // Light compression, default (0.167=~6x)
#define L_compr_high    0.334                // Light compression, surrounded by edges (0.334=~3x)

#define D_overshoot     0.009                // Max dark overshoot before compression [>0.001]
#define D_compr_low     0.250                // Dark compression, default (0.250=4x)
#define D_compr_high    0.500                // Dark compression, surrounded by edges (0.500=2x)

#define scale_lim       0.1                  // Abs max change before compression [>0.01]
#define scale_cs        0.056                // Compression slope above scale_lim

#define lowthr_mxw      0.1                  // Edge value for max lowthr weight [>0.01]

#define pm_p            0.5                  // Power mean p-value [>0-1.0]
//-------------------------------------------------------------------------------------------------

#define max4(a,b,c,d)  ( max(max(a, b), max(c, d)) )

// Soft if, fast linear approx
#define soft_if(a,b,c) ( sat((a + b + c + 0.025455)/(maxedge + 0.013636) - 0.85) )

// Soft limit, modified tanh approx
#define soft_lim(v,s)  ( sat(abs(v/s)*(27.0 + pow(v/s, 2.0))/(27.0 + 9.0*pow(v/s, 2.0)))*s )

// Weighted power mean
#define wpmean(a,b,w)  ( pow(w*pow(abs(a), pm_p) + abs(1.0-w)*pow(abs(b), pm_p), (1.0/pm_p)) )

// Get destination pixel values
#define get(x,y)       ( sat(HOOKED_texOff(vec2(x, y)).rgb) )
#define sat(x)         ( clamp(x, 0.0, 1.0) )
#define dxdy(val)      ( length(fwidth(val)) ) // edgemul = 2.2

// Colour to luma, fast approx gamma, avg of rec. 709 & 601 luma coeffs
#define CtL(RGB)       ( sqrt(dot(RGB*RGB, vec3(0.2558, 0.6511, 0.0931))) )

vec4 hook() {

    // [                c22               ]
    // [           c24, c9,  c23          ]
    // [      c21, c1,  c2,  c3, c18      ]
    // [ c19, c10, c4,  c0,  c5, c11, c16 ]
    // [      c20, c6,  c7,  c8, c17      ]
    // [           c15, c12, c14          ]
    // [                c13               ]
    vec3 c[25] = vec3[](get( 0, 0), get(-1,-1), get( 0,-1), get( 1,-1), get(-1, 0),
                        get( 1, 0), get(-1, 1), get( 0, 1), get( 1, 1), get( 0,-2),
                        get(-2, 0), get( 2, 0), get( 0, 2), get( 0, 3), get( 1, 2),
                        get(-1, 2), get( 3, 0), get( 2, 1), get( 2,-1), get(-3, 0),
                        get(-2, 1), get(-2,-1), get( 0,-3), get( 1,-2), get(-1,-2));

    float e[25] = float[](dxdy(c[0]),  dxdy(c[1]),  dxdy(c[2]),  dxdy(c[3]),  dxdy(c[4]),
                          dxdy(c[5]),  dxdy(c[6]),  dxdy(c[7]),  dxdy(c[8]),  dxdy(c[9]),
                          dxdy(c[10]), dxdy(c[11]), dxdy(c[12]), dxdy(c[13]), dxdy(c[14]),
                          dxdy(c[15]), dxdy(c[16]), dxdy(c[17]), dxdy(c[18]), dxdy(c[19]),
                          dxdy(c[20]), dxdy(c[21]), dxdy(c[22]), dxdy(c[23]), dxdy(c[24]));

    // Allow for higher overshoot if the current edge pixel is surrounded by similar edge pixels
    float maxedge = max4( max4(e[1],e[2],e[3],e[4]), max4(e[5],e[6],e[7],e[8]),
                          max4(e[9],e[10],e[11],e[12]), e[0] );

    // [          x          ]
    // [       z, x, w       ]
    // [    z, z, x, w, w    ]
    // [ y, y, y, 0, y, y, y ]
    // [    w, w, x, z, z    ]
    // [       w, x, z       ]
    // [          x          ]
    float sbe = soft_if(e[2],e[9], e[22])*soft_if(e[7],e[12],e[13])  // x dir
              + soft_if(e[4],e[10],e[19])*soft_if(e[5],e[11],e[16])  // y dir
              + soft_if(e[1],e[24],e[21])*soft_if(e[8],e[14],e[17])  // z dir
              + soft_if(e[3],e[23],e[18])*soft_if(e[6],e[20],e[15]); // w dir

    vec2 cs = mix( vec2(L_compr_low,  D_compr_low),
                   vec2(L_compr_high, D_compr_high), sat(2.4002*sbe - 2.282) );

    // RGB to luma
    float c0_Y = CtL(c[0]);

    float luma[25] = float[](c0_Y, CtL(c[1]), CtL(c[2]), CtL(c[3]), CtL(c[4]), CtL(c[5]), CtL(c[6]),
                             CtL(c[7]),  CtL(c[8]),  CtL(c[9]),  CtL(c[10]), CtL(c[11]), CtL(c[12]),
                             CtL(c[13]), CtL(c[14]), CtL(c[15]), CtL(c[16]), CtL(c[17]), CtL(c[18]),
                             CtL(c[19]), CtL(c[20]), CtL(c[21]), CtL(c[22]), CtL(c[23]), CtL(c[24]));

    // Precalculated default squared kernel weights
    const vec3 w1 = vec3(0.5,           1.0, 1.41421356237); // 0.25, 1.0, 2.0
    const vec3 w2 = vec3(0.86602540378, 1.0, 0.54772255751); // 0.75, 1.0, 0.3

    // Transition to a concave kernel if the center edge val is above thr
    vec3 dW = pow(mix( w1, w2, sat(5.28*e[0] - 0.82)), vec3(2.0));

    // Use lower weights for pixels in a more active area relative to center pixel area
    // This results in narrower and less visible overshoots around sharp edges
    float modif_e0 = 3.0 * e[0] + 0.0090909;

    float weights[12]  = float[](( min(modif_e0/e[1],  dW.y) ),
                                 ( dW.x ),                  
                                 ( min(modif_e0/e[3],  dW.y) ),
                                 ( dW.x ),                  
                                 ( dW.x ),                  
                                 ( min(modif_e0/e[6],  dW.y) ),
                                 ( dW.x ),                  
                                 ( min(modif_e0/e[8],  dW.y) ),
                                 ( min(modif_e0/e[9],  dW.z) ),
                                 ( min(modif_e0/e[10], dW.z) ),
                                 ( min(modif_e0/e[11], dW.z) ),
                                 ( min(modif_e0/e[12], dW.z) ));

    weights[0] = (max(max((weights[8]  + weights[9])/4.0,  weights[0]), 0.25) + weights[0])/2.0;
    weights[2] = (max(max((weights[8]  + weights[10])/4.0, weights[2]), 0.25) + weights[2])/2.0;
    weights[5] = (max(max((weights[9]  + weights[11])/4.0, weights[5]), 0.25) + weights[5])/2.0;
    weights[7] = (max(max((weights[10] + weights[11])/4.0, weights[7]), 0.25) + weights[7])/2.0;

    // Calculate the negative part of the laplace kernel and the low threshold weight
    float lowthrsum   = 0.0;
    float weightsum   = 0.0;
    float neg_laplace = 0.0;

    for (int pix = 0; pix < 12; ++pix)
    {
        float lowthr = clamp((29.04*e[pix + 1] - 0.221), 0.01, 1.0);

        neg_laplace += luma[pix+1] * weights[pix] * lowthr;
        weightsum   += weights[pix] * lowthr;
        lowthrsum   += lowthr / 12.0;
    }

    neg_laplace = neg_laplace / weightsum;

    // Compute sharpening magnitude function
    float sharpen_val = curve_height/(curve_height*curveslope*pow((e[0]*2.2), 3.5) + 0.625);

    // Calculate sharpening diff and scale
    float sharpdiff = (c0_Y - neg_laplace)*(lowthrsum*sharpen_val + 0.01);

    // Calculate local near min & max, partial sort
    float temp;

    for (int i1 = 0; i1 < 24; i1 += 2)
    {
        temp = luma[i1];
        luma[i1]   = min(luma[i1], luma[i1+1]);
        luma[i1+1] = max(temp, luma[i1+1]);
    }

    for (int i2 = 24; i2 > 0; i2 -= 2)
    {
        temp = luma[0];
        luma[0]    = min(luma[0], luma[i2]);
        luma[i2]   = max(temp, luma[i2]);

        temp = luma[24];
        luma[24] = max(luma[24], luma[i2-1]);
        luma[i2-1] = min(temp, luma[i2-1]);
    }

    for (int i1 = 1; i1 < 24-1; i1 += 2)
    {
        temp = luma[i1];
        luma[i1]   = min(luma[i1], luma[i1+1]);
        luma[i1+1] = max(temp, luma[i1+1]);
    }

    for (int i2 = 24-1; i2 > 1; i2 -= 2)
    {
        temp = luma[1];
        luma[1]    = min(luma[1], luma[i2]);
        luma[i2]   = max(temp, luma[i2]);

        temp = luma[24-1];
        luma[24-1] = max(luma[24-1], luma[i2-1]);
        luma[i2-1] = min(temp, luma[i2-1]);
    }

    float nmax = (max(luma[23], c0_Y)*2.0 + luma[24])/3.0;
    float nmin = (min(luma[1],  c0_Y)*2.0 + luma[0])/3.0;

    float min_dist  = min(abs(nmax - c0_Y), abs(c0_Y - nmin));
    float pos_scale = min_dist + L_overshoot;
    float neg_scale = min_dist + D_overshoot;

    pos_scale = min(pos_scale, scale_lim*(1.0 - scale_cs) + pos_scale*scale_cs);
    neg_scale = min(neg_scale, scale_lim*(1.0 - scale_cs) + neg_scale*scale_cs);

    // Soft limited anti-ringing with tanh, wpmean to control compression slope
    sharpdiff = wpmean(max(sharpdiff, 0.0), soft_lim( max(sharpdiff, 0.0), pos_scale ), cs.x )
              - wpmean(min(sharpdiff, 0.0), soft_lim( min(sharpdiff, 0.0), neg_scale ), cs.y );

    float sharpdiff_lim = sat(c0_Y + sharpdiff) - c0_Y;
    float satmul = (c0_Y + max(sharpdiff_lim*0.9, sharpdiff_lim)*1.03 + 0.03)/(c0_Y + 0.03);
    vec3 res = c0_Y + (sharpdiff_lim*3.0 + sharpdiff)/4.0 + (c[0] - c0_Y)*satmul;

    return vec4(video_level_out == true ? res + HOOKED_texOff(0).rgb - c[0] : res, HOOKED_texOff(0).a);
}
