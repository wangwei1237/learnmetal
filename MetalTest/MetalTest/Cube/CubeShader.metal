//
//  ColorTriangleShader.metal
//  MetalTest
//
//  Created by wangwei on 2018/10/15.
//  Copyright © 2018 wangwei. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
    float4 color;
};

struct Uniforms {
    float4x4 modelViewProjectionMatrix;
};

vertex Vertex cube_basic_vertex(constant Vertex* vertex_array [[buffer(0)]],
                                constant Uniforms &uniforms [[buffer(1)]], 
                           unsigned int vid [[vertex_id]]) {
    Vertex out;
    Vertex in    = vertex_array[vid];
    out.position = uniforms.modelViewProjectionMatrix * float4(in.position);
    out.color    = in.color;
    
    return out;
}

fragment half4 cube_basic_fragment(Vertex vert [[stage_in]]) {
    return half4(vert.color);
}

