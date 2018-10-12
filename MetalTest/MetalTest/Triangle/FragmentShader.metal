//
//  FragmentShader.metal
//  MetalTriangle
//
//  Created by wangwei on 2018/10/8.
//  Copyright © 2018 wangwei. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

fragment half4 basic_fragment() {
    return half4(0.2, 0.6, 0.7, 1.0);
}
