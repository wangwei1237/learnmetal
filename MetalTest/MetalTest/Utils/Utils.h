//
//  Utils.h
//  MetalTest
//
//  Created by wangwei on 2018/10/19.
//  Copyright © 2018 wangwei. All rights reserved.
//

#ifndef Utils_h
#define Utils_h

float sum(float a, float b);
float distance(float2 point, float2 center, float radius);
float smootherstep(float e1, float e2, float x);
float4 grayColor(float4 colorIn);
float4 sobel(uint2 gid, int sobelStep, metal::texture2d<float, metal::access::read> src);
struct VertexIn {
    float4 position [[position]];
    float4 color;
    float4 texCoord;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 textCoord;
    bool isGray;
};

#endif /* Utils_h */
