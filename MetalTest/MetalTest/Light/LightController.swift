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

class LightController: UIViewController {
    //[[ properties
    var device: MTLDevice!                      = nil
    var metalLayer: CAMetalLayer!               = nil
    var pipelineState: MTLComputePipelineState! = nil
    var commandQueue: MTLCommandQueue!          = nil
    var timer: CADisplayLink!                   = nil
    var t: Float                                = 0
    var tBuffer: MTLBuffer!                     = nil
    var tapPoint: float2!                       = nil
    var tapPointBuffer: MTLBuffer!              = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        initViewStyle()
        initMTLDevice()
        initMTLLayer()
        initMTLBuffer()
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
        
        self.title = "渲染动图"
        self.view.backgroundColor = UIColor.white
    }
    
    func initMTLDevice() {
        self.device = MTLCreateSystemDefaultDevice()
    }
    
    func initMTLLayer() {
        self.metalLayer = CAMetalLayer()
        
        self.metalLayer.device      = self.device
        self.metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly  = false
        metalLayer.frame            = self.view.layer.frame
        
        var drawableSize        = self.view.bounds.size
        drawableSize.width     *= self.view.contentScaleFactor
        drawableSize.height    *= self.view.contentScaleFactor
        metalLayer.drawableSize = drawableSize
        
        self.view.layer.addSublayer(metalLayer)
    }
    
    func initMTLBuffer() {
        self.tapPoint = float2(0.0, 0.0)
        self.tBuffer = self.device.makeBuffer(length: MemoryLayout<Float>.size, options: [])
        self.tapPointBuffer = self.device.makeBuffer(length: MemoryLayout<float2>.size, options: [])
    }
    
    func initPipelineState() {
        let defaultLibrary = self.device.makeDefaultLibrary()
        let computeFunc     = defaultLibrary?.makeFunction(name: "l_compute")
        do {
            try self.pipelineState = self.device.makeComputePipelineState(function: computeFunc!)
        } catch let e{
            print("\(e)")
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
        self.t += 0.01
        let bufferPoint = self.tBuffer.contents()
        memcpy(bufferPoint, &self.t, MemoryLayout<Float>.size)
        let tapBufferPoint = self.tapPointBuffer.contents()
        memcpy(tapBufferPoint, &self.tapPoint, MemoryLayout<float2>.size)
        
        let drawable = self.metalLayer.nextDrawable()
        let commandBuffer = self.commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        
        commandEncoder?.setComputePipelineState(self.pipelineState)
        commandEncoder?.setTexture(drawable!.texture, index: 0)
        commandEncoder?.setBuffer(self.tBuffer, offset: 0, index: 1)
        commandEncoder?.setBuffer(self.tapPointBuffer, offset: 0, index: 2)
        
        let threadGroupSize = MTLSizeMake(8, 8, 1)
        let threadGroups = MTLSizeMake(drawable!.texture.width / threadGroupSize.width, drawable!.texture.height / threadGroupSize.height, 1)
        commandEncoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        commandEncoder?.endEncoding()
        
        commandBuffer?.present(drawable!)
        commandBuffer?.commit()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let t: UITouch = touch as! UITouch
            //当在屏幕上连续拍动两下时，背景恢复为白色
            if(t.tapCount == 2) {
                //self.view.backgroundColor = UIColor.white
            } else if(t.tapCount == 1) { //当在屏幕上单击时，屏幕变为红色
                //self.view.backgroundColor = UIColor.red
            }
            
            var point = (touch as AnyObject).location(in: self.view)
            
            let scale = self.metalLayer.contentsScale
            point.x  *= scale
            point.y  *= scale
            //print("(\(point.x),\(point.y))")
            self.tapPoint = float2(Float(point.x), Float(point.y))
        }
    }
}
