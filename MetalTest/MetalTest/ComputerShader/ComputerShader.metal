//
//  ColorTriangleShader.metal
//  MetalTest
//
//  Created by wangwei on 2018/10/15.
//  Copyright © 2018 wangwei. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void cs_compute(texture2d<float, access::write> output [[texture(0)]],
                       uint2 gid [[thread_position_in_grid]]) {
    int width     = output.get_width();
    int height    = output.get_height();
//    float red     = float(gid.x) / float(width);
//    float green   = float(gid.y) / float(height);
    float2 center = float2(float(width) / float(3) * 2, float(height) / float(3));
    float2 uv     = float2(float2(gid) - center);
    bool inside   = length(uv) < 80;
    
    float distToCircle = length(uv) / length(float2(0, 0) - center);
    output.write(inside ? float4(0) : float4(1, 0.7, 0.0, 1) * distToCircle, gid);
}
