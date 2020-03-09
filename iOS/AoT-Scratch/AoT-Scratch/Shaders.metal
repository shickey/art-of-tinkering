//
//  Shaders.metal
//  Scraptchure
//
//  Created by Sean Hickey on 10/11/19.
//  Copyright © 2019 Massachusetts Institute of Technology. All rights reserved.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;

#define ROOT_3 1.73205080756f

extern "C" { namespace coreimage {

    float4 chromaKey(sampler src, float3 keyColor, float threshold) {
        float4 input = src.sample(src.coord());
        float3 linearKey = srgb_to_linear(keyColor);
        float normalizedDist = distance(input.rgb, linearKey) / ROOT_3;
        if (normalizedDist < threshold) {
            return float4(0, 0, 0, 0);
        }
        else if (normalizedDist < clamp(threshold + 0.05f, 0.0f, 1.0)) {
            // Linear alpha blend
            float outerThreshold = clamp(threshold + 0.05f, 0.0f, 1.0);
            float blend = 1.0 - ((outerThreshold - normalizedDist) / 0.05);
            return float4(input.rgb, blend);
        }
        return input;
    }

}}


