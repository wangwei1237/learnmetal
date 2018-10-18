//
//  ColorTriangleShader.metal
//  MetalTest
//
//  Created by wangwei on 2018/10/15.
//  Copyright © 2018 wangwei. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

float l_distance(float2 point, float2 center, float radius) {
    return length(point - center) - radius;
}

float l_smootherstep(float e1, float e2, float x) {
    x = clamp((x - e1) / (e2 - e1), 0.0, 1.0);
    return x * x * x * (x * (x * 6 - 15) + 10);
}

kernel void l_compute(texture2d<float, access::write> output [[texture(0)]],
                       constant float &t [[buffer(1)]],
                       constant float2 &tp [[buffer(2)]],
                       uint2 gid [[thread_position_in_grid]]) {
    float  radius = 80;
    int width     = output.get_width();
    int height    = output.get_height();
    
    float2 center = float2(float(width / 2), float(height / 2));
    float inside  = l_distance(float2(gid), center, radius);
    float w       = sqrt(radius * radius - (gid.x - center.x) * (gid.x - center.x) - (gid.y - center.y) * (gid.y - center.y));
    w = w / radius;
    float3 normal  = normalize(float3((gid.x -center.x) / radius, (gid.y -center.y) / radius, w));
    float3 source  = normalize(float3(cos(t), sin(t), 1));
    float  light   = dot(normal, source);
    float m = l_smootherstep(radius - 1.5, radius + 1.5, inside + radius);
    float4 pixel = mix(float4(light), float4(0.0), m);
    output.write((inside < 0) ? pixel : float4(0.0), gid);
}
