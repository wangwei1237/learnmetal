//
//  VertexShader.metal
//  MetalTriangle
//
//  Created by wangwei on 2018/10/8.
//  Copyright © 2018 wangwei. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 basic_vertex(constant packed_float3* vertex_array[[buffer(0)]],
                            unsigned int vid[[vertex_id]]) {
    return float4(vertex_array[vid], 1.0);
}

