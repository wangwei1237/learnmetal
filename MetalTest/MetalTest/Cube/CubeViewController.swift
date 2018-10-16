//
//  TriangleViewController.swift
//  MetalTest
//
//  Created by wangwei on 2018/10/11.
//  Copyright © 2018 wangwei. All rights reserved.
//

import UIKit
import Metal
import QuartzCore
import simd

class CubeViewController: UIViewController {
    //[[ properties
    var device: MTLDevice!                     = nil
    var metalLayer: CAMetalLayer!              = nil
    var vertexBuffer: MTLBuffer!               = nil
    var indexBuffer: MTLBuffer!                = nil
    var uniformBuffer: MTLBuffer!              = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue!         = nil
    var timer: CADisplayLink!                  = nil
    
    let vertexData: [Float] = [
        -1.0, -1.0, -1.0, 1.0, 1.0, 0.0, 0.0, 1.0,
         1.0, -1.0, -1.0, 1.0, 0.0, 1.0, 0.0, 1.0,
         1.0, -1.0,  1.0, 1.0, 0.0, 0.0, 1.0, 1.0,
        -1.0, -1.0,  1.0, 1.0, 0.0, 1.0, 0.0, 1.0,
        
        -1.0,  1.0, -1.0, 1.0, 0.0, 1.0, 0.0, 1.0,
         1.0,  1.0, -1.0, 1.0, 0.0, 0.0, 1.0, 1.0,
         1.0,  1.0,  1.0, 1.0, 1.0, 0.0, 0.0, 1.0,
        -1.0,  1.0,  1.0, 1.0, 0.0, 0.0, 1.0, 1.0,
        ]
    //]]
    
    let indexData: [UInt16] = [
        2, 3, 7, 7, 6, 2,    //前
        1, 2, 6, 6, 5, 1,    //右
        4, 5, 6, 6, 7, 4,    //上
        0, 3, 2, 2, 1, 0,    //下
        0, 4, 7, 7, 3, 0,    //左
        0, 1, 5, 5, 4, 0,    //后
    ]
    
    var rotation : Float = 1.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        initViewStyle()
        initMTLDevice()
        initMTLLayer()
        initVertexBuffer()
        initPipelineState()
        initCommandQueue()
        
        timer = CADisplayLink(target: self, selector: #selector(drawloop))
        timer.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
    }
    
    func initViewStyle() {
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        let navBarHeight   = self.navigationController?.navigationBar.bounds.size.height
        let viewTranslateY = navBarHeight! + statusBarHeight
        
        var viewSize       = self.view.bounds.size
        viewSize.height   -= viewTranslateY
        var viewOriginal   = self.view.frame.origin
        viewOriginal.y    += viewTranslateY
        
        self.view.bounds.size  = viewSize
        self.view.frame.origin = viewOriginal
        self.view.frame.size   = viewSize
        
        self.title = "立方体"
        self.view.backgroundColor = UIColor.white
    }
    
    func initMTLDevice() {
        self.device = MTLCreateSystemDefaultDevice()
    }
    
    func initMTLLayer() {
        self.metalLayer = CAMetalLayer()
        
        self.metalLayer.device      = self.device
        self.metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly  = true
        metalLayer.frame            = self.view.layer.frame
        
        var drawableSize        = self.view.bounds.size
        drawableSize.width     *= self.view.contentScaleFactor
        drawableSize.height    *= self.view.contentScaleFactor
        metalLayer.drawableSize = drawableSize
        
        self.view.layer.addSublayer(metalLayer)
    }
    
    func initVertexBuffer() {
        let dataSize      = self.vertexData.count * MemoryLayout<Float>.size
        self.vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: MTLResourceOptions(rawValue: UInt(0)))
        
        self.indexBuffer  = device.makeBuffer(bytes: indexData, length: MemoryLayout<UInt16>.size * indexData.count, options: [])
        
        self.uniformBuffer = device.makeBuffer(length: MemoryLayout<float4x4>.size, options: [])
    }
    
    func initPipelineState() {
        let defaultLibrary = self.device.makeDefaultLibrary()
        let vertexFunc     = defaultLibrary?.makeFunction(name: "cube_basic_vertex")
        let fragmentFunc   = defaultLibrary?.makeFunction(name: "cube_basic_fragment")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction   = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            try self.pipelineState = self.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            
        }
    }
    
    func initCommandQueue() {
        self.commandQueue = self.device.makeCommandQueue()
    }
    
    @objc func drawloop() {
        self.render()
    }
    
    func render() {
        // metal layer上调用nextDrawable() ，它会返回你需要绘制到屏幕上的纹理(texture)
        let drawable = metalLayer.nextDrawable()
        
        // 创建一个Render Pass Descriptor，配置什么纹理会被渲染到、clear color，以及其他的配置
        let renderPassDesciptor = MTLRenderPassDescriptor()
        renderPassDesciptor.colorAttachments[0].texture = drawable?.texture
        // 设置load action为clear，也就是说在绘制之前，把纹理清空
        renderPassDesciptor.colorAttachments[0].loadAction = .clear
        // 绘制的背景颜色设置为绿色
        renderPassDesciptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.8, 0.5, 1.0)
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        // 创建一个渲染命令编码器(Render Command Encoder)
        // 创建一个command encoder，并指定你之前创建的pipeline和顶点
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDesciptor)
        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setFrontFacing(.clockwise)
        renderEncoder?.setCullMode(.back)
        setUniforms()
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder?.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        
        renderEncoder?.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.size, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        
        renderEncoder?.endEncoding()
        
        commandBuffer?.present(drawable!)
        commandBuffer?.commit()
    }
    
    func setUniforms() {
        let cameraPosition = vector_float3(0, 0, -3)
        
        let scaled = scalingMatrix(scale: 0.5)
        rotation += 1 / 100 * Float.pi / 4
        let rotatedY = rotationMatrix(angle: rotation, axis: float3(0, 1, 0))
        let rotatedX = rotationMatrix(angle: Float.pi / 6, axis: float3(1, 0, 0))
        let modelMatrix = matrix_multiply(matrix_multiply(rotatedX, rotatedY), scaled)
        
        let viewMatrix = translationMatrix(position: cameraPosition)
        let aspect = self.metalLayer.drawableSize.width / metalLayer.drawableSize.height
        let projMatrix = projectionMatrix(near: 1.0, far: 100, aspect: Float(aspect), fovy: 1)
        let modelViewProjectionMatrix = matrix_multiply(projMatrix, matrix_multiply(viewMatrix, modelMatrix))
        
        let bufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: modelViewProjectionMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
    }
}
