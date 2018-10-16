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

vertex Vertex ct_basic_vertex(constant Vertex* vertex_array[[buffer(0)]],
                           unsigned int vid[[vertex_id]]) {
    return vertex_array[vid];
}

fragment float4 ct_basic_fragment(Vertex vert [[stage_in]]) {
    return vert.color;
}

