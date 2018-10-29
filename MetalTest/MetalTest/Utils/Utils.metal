//
//  Utils.metal
//  MetalTest
//
//  Created by wangwei on 2018/10/19.
//  Copyright © 2018 wangwei. All rights reserved.
//
#ifndef __UTILS
#define __UTILS


#include <metal_stdlib>
#include "Utils.h"
using namespace metal;

float sum(float a, float b) {
    return a + b;
}

float distance(float2 point, float2 center, float radius) {
    return length(point - center) - radius;
}

float smootherstep(float e1, float e2, float x) {
    x = clamp((x - e1) / (e2 - e1), 0.0, 1.0);
    return x * x * x * (x * (x * 6 - 15) + 10);
}

float4 grayColor(float4 colorIn) {
    float3 grayVector =float3(0.3, 0.59, 0.11);
    return float4(float3(dot(grayVector, float3(colorIn.xyz))), 1.0);
}

#endif  //__UTILS

