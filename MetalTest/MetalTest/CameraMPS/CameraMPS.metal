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

vertex VertexOut camps_basic_vertex(constant VertexIn* vertex_array [[buffer(0)]],
                                 unsigned int vid [[vertex_id]],
                                 constant bool &isGray [[buffer(1)]]) {
    VertexOut out;
    out.position = vertex_array[vid].position;
    out.color    = vertex_array[vid].color;
    out.textCoord= float2(vertex_array[vid].texCoord.xy);
    out.isGray   = isGray;
    
    return out;
}

fragment float4 camps_basic_fragment(VertexOut vert [[stage_in]],
                                  texture2d<float> colorTexture [[texture(0)]]) {
    
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    float4 colorSample = colorTexture.sample(textureSampler, vert.textCoord);
    //
    if(vert.isGray) {
        return grayColor(colorSample);
    } else {
        return colorSample;
    }
    //return float4(1.0, 0.0, 0.0, 1.0);
}


