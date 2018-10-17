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

class CSViewController: UIViewController {
    //[[ properties
    var device: MTLDevice!                      = nil
    var metalLayer: CAMetalLayer!               = nil
    var pipelineState: MTLComputePipelineState! = nil
    var commandQueue: MTLCommandQueue!          = nil
    var timer: CADisplayLink!                   = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        initViewStyle()
        initMTLDevice()
        initMTLLayer()
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
        
        self.title = "计算着色器"
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
    
    
    func initPipelineState() {
        let defaultLibrary = self.device.makeDefaultLibrary()
        let computeFunc     = defaultLibrary?.makeFunction(name: "cs_compute")
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
        let drawable = self.metalLayer.nextDrawable()
        let commandBuffer = self.commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        
        commandEncoder?.setComputePipelineState(self.pipelineState)
        commandEncoder?.setTexture(drawable!.texture, index: 0)
        
        let threadGroupSize = MTLSizeMake(8, 8, 1)
        let threadGroups = MTLSizeMake(drawable!.texture.width / threadGroupSize.width, drawable!.texture.height / threadGroupSize.height, 1)
        commandEncoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        commandEncoder?.endEncoding()
        
        commandBuffer?.present(drawable!)
        commandBuffer?.commit()

    }
}
