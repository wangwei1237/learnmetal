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
import AVFoundation
import MetalKit
import MetalPerformanceShaders

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    //[[ properties
    var device:MTLDevice!                     = nil
    var metalLayer:CAMetalLayer!              = nil
    var vertexBuffer:MTLBuffer!               = nil
    var pipelineState:MTLRenderPipelineState! = nil
    var commandQueue:MTLCommandQueue!         = nil
    var timer:CADisplayLink!                  = nil
    
    var captureSession:AVCaptureSession!         = nil
    var captureDeviceInput:AVCaptureDeviceInput! = nil
    var captureOutput:AVCaptureVideoDataOutput!  = nil
    var texture:MTLTexture!                      = nil
    var processQueue:DispatchQueue!              = nil
    
    var isGray:Bool!                             = false
    let button:UIButton!                         = UIButton(type: .system)
    var isGrayBuffer: MTLBuffer!                 = nil
    
    let vertexData:[Float] = [
        0.8,  0.8, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0,
        -0.8, -0.8, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0,0.0, 0.0,
        0.8, -0.8, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0,0.0, 0.0,
        
        0.8,  0.8, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0,0.0, 0.0,
        -0.8,  0.8, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0,0.0, 0.0,
        -0.8, -0.8, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0,0.0, 0.0,
//        -1.0,  0.5, 0.0,0.
//        -0.5, -0.5, 0.0,
//        0.0,  0.5, 0.0,
        ]
    //]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        initViewStyle()
        
        initMTLDevice()
        initMTLLayer()
        initControlButton()
        initVertexBuffer()
        initPipelineState()
        initCommandQueue()
        initCaptureSession()
        
        timer = CADisplayLink(target: self, selector: #selector(drawloop))
        timer.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.captureSession.stopRunning()
        print("end")
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
        
        self.title = "渲染摄像头"
        //self.navigationItem.leftBarButtonItem?.title = "返回"
        self.view.backgroundColor = UIColor.white
    }
    
    func initControlButton() {
        //let y2:Float = Float(self.view.bounds.height / 20.0 * 18.0)
        let viewFrameOrigin = self.view.frame.origin
        var buttonFrameOrigin = viewFrameOrigin
        buttonFrameOrigin.y  = 520
        buttonFrameOrigin.x  = 40
        self.button.frame = CGRect(x: buttonFrameOrigin.x, y: buttonFrameOrigin.y, width: 100, height: 40)
        self.button.setTitle("灰度", for: .normal);
        self.button.backgroundColor = UIColor.blue;
        self.button.addTarget(self, action:#selector(tapped(_:)), for:.touchUpInside)
        self.view.addSubview(self.button)
    }
    
    @objc func tapped(_ button:UIButton) {
        self.isGray = !self.isGray;
        if self.isGray {
            self.button.setTitle("彩色", for: .normal)
        } else {
            self.button.setTitle("灰度", for: .normal)
        }
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
    
    func initVertexBuffer() {
        let dataSize      = self.vertexData.count * MemoryLayout<Float>.size
        self.vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: MTLResourceOptions(rawValue: UInt(0)))
        self.isGrayBuffer = device.makeBuffer(length: MemoryLayout<Bool>.size, options: [])
    }
    
    func initPipelineState() {
        let defaultLibrary = self.device.makeDefaultLibrary()
        let vertexFunc     = defaultLibrary?.makeFunction(name: "ca_basic_vertex")
        let fragmentFunc   = defaultLibrary?.makeFunction(name: "ca_basic_fragment")
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
        if let _ = self.texture {
            let bufferPoint = self.isGrayBuffer.contents()
            memcpy(bufferPoint, &self.isGray, MemoryLayout<Bool>.size)
            
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
            renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder?.setVertexBuffer(isGrayBuffer, offset: 0, index: 1)
            renderEncoder?.setFragmentTexture(self.texture, index: 0)
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 2)
            renderEncoder?.endEncoding()
            
            commandBuffer?.present(drawable!)
            commandBuffer?.commit()
        }
    }
    
    func initCaptureSession() {
        self.captureSession = AVCaptureSession()
        self.captureOutput = AVCaptureVideoDataOutput()
        self.processQueue = DispatchQueue.global(qos: .default)
        
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
        do {
            try self.captureDeviceInput = AVCaptureDeviceInput(device: device!)
        } catch let error as NSError {
            print(error)
        }
        
        if self.captureSession.canAddInput(self.captureDeviceInput) {
            self.captureSession.addInput(self.captureDeviceInput)
        }
        
        if self.captureSession.canAddOutput(self.captureOutput) {
            self.captureSession.addOutput(self.captureOutput)
        }
        
        self.captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        self.captureOutput.alwaysDiscardsLateVideoFrames = false
        self.captureOutput.setSampleBufferDelegate(self, queue: self.processQueue)
        
        self.captureSession.beginConfiguration()
        self.captureSession.sessionPreset = .medium
        self.captureSession.commitConfiguration()
        
        let connection = self.captureOutput.connection(with: .video)
        connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        
        self.captureSession.startRunning()
    }
    
    func captureOutput(_: AVCaptureOutput, didOutput: CMSampleBuffer, from: AVCaptureConnection) {
        let localImg = self.getImageData(sampleBuffer: didOutput)
        //print("localImg info: \(String(describing: localImg?.size.width)),\(String(describing: localImg?.size.height))")
        
        if localImg != nil {
            //self.metalLayer.drawableSize = localImg!.size
            let textureLoader = MTKTextureLoader(device: self.device)
            do {
                try self.texture = textureLoader.newTexture(cgImage: (localImg!.cgImage)!, options: [.origin: MTKTextureLoader.Origin.flippedVertically])
            } catch let error as NSError{
                print(error)
            }
        }
    }
    
    func captureOutput(_: AVCaptureOutput, didDrop: CMSampleBuffer, from: AVCaptureConnection) {
    }
    
    func getImageData(sampleBuffer: CMSampleBuffer!)-> UIImage? {
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            
            CVPixelBufferLockBaseAddress(imageBuffer,[])
            let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: baseAddress,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | (CGImageAlphaInfo.premultipliedFirst.rawValue &
                                        CGBitmapInfo.alphaInfoMask.rawValue) )
            
            let quartzImage = context?.makeImage()
            CVPixelBufferUnlockBaseAddress(imageBuffer,[])
            
            if let quartzImage = quartzImage {
                let image = UIImage(cgImage: quartzImage)
                return image
            }
        }
        
        return nil
    }
}
