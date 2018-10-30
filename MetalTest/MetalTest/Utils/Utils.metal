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

float4 sobel(uint2 gid, int sobelStep, metal::texture2d<float, metal::access::read> src) {
    float3 kRec709Luma = float3(0.2126, 0.7152, 0.0722); // 把rgba转成亮度值
    
    float4 topLeft     = src.read(uint2(gid.x - sobelStep, gid.y - sobelStep)); // 左上
    float4 top         = src.read(uint2(gid.x, gid.y - sobelStep)); // 上
    float4 topRight    = src.read(uint2(gid.x + sobelStep, gid.y - sobelStep)); // 右上
    float4 centerLeft  = src.read(uint2(gid.x - sobelStep, gid.y)); // 中左
    float4 centerRight = src.read(uint2(gid.x + sobelStep, gid.y)); // 中右
    float4 bottomLeft  = src.read(uint2(gid.x - sobelStep, gid.y + sobelStep)); // 下左
    float4 bottom      = src.read(uint2(gid.x, gid.y + sobelStep)); // 下中
    float4 bottomRight = src.read(uint2(gid.x + sobelStep, gid.y + sobelStep)); // 下右
    
    float4 h = -topLeft - 2.0 * top - topRight + bottomLeft + 2.0 * bottom + bottomRight; // 横方向差别
    float4 v = -bottom - 2.0 * centerLeft - topLeft + bottomRight + 2.0 * centerRight + topRight; // 竖方向差别
    
    float  grayH  = dot(h.rgb, kRec709Luma); // 转换成亮度
    float  grayV  = dot(v.rgb, kRec709Luma); // 转换成亮度
    
    // sqrt(h^2 + v^2)，相当于求点到(h, v)的距离，所以可以用length
    float color = length(float2(grayH, grayV));
    
    return float4(float3(color), 1.0);
}
#endif  //__UTILS

