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

kernel void cs_compute(texture2d<float, access::write> output [[texture(0)]],
                       uint2 gid [[thread_position_in_grid]]) {
    float  radius = 80;
    int width     = output.get_width();
    int height    = output.get_height();
    float2 center = float2(float(width / 3 * 2), float(height / 3));
    float inside  = distance(float2(gid), center, radius);
    float denominator  = distance(float2(0, 0), center, radius);
    float distToCircle = inside / denominator;
    
    // [[begin 边缘平滑处理，去锯齿
    float4 sun    = float4(1, 0.7, 0.0, 1) * (1 - distToCircle);
    float4 planet = float4(0);
    float m = smootherstep(radius - 1, radius + 1, inside + radius);
    float4 pixel = mix(planet, sun, m);
    // end]]
    
    output.write(pixel, gid);
}
