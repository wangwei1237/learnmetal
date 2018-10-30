//
//  ColorTriangleShader.metal
//  MetalTest
//
//  Created by wangwei on 2018/10/15.
//  Copyright © 2018 wangwei. All rights reserved.
//

#include <metal_stdlib>
#include "../Utils/Utils.h"
using namespace metal;

kernel void ca_cs_compute(texture2d<float, access::write> output [[texture(0)]],
                          texture2d<float, access::read> src [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    
    float2 center = float2(output.get_width() / 2, output.get_height() / 2);
    float radius  = 30;
    float4 pixel  = float4(0.0);
    float m       = 0;
    
    if (length(float2(gid) - center) < radius) {
        m     = smootherstep(radius - 2, radius, length(float2(gid) - center));
        pixel = float4(sobel(gid, 2, src));
        if (m > 0 && m < 1) {
            pixel = float4(mix(pixel, float4(0.0), m));
        }
        output.write(pixel, gid);
    } else {
        m     = smootherstep(radius, radius + 2, length(float2(gid) - center));
        pixel = float4(src.read(gid));
        if (m > 0 && m < 1) {
            pixel = float4(mix(pixel, float4(0.0), m));
        }
        output.write(pixel, gid);
    }
    
}

