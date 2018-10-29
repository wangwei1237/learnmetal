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

class CameraMPSViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    //[[ properties
    var device:MTLDevice!                     = nil
    var metalLayer:CAMetalLayer!              = nil
    var commandQueue:MTLCommandQueue!         = nil
    var timer:CADisplayLink!                  = nil
    
    var captureSession:AVCaptureSession!         = nil
    var captureDeviceInput:AVCaptureDeviceInput! = nil
    var captureOutput:AVCaptureVideoDataOutput!  = nil
    var texture:MTLTexture!                      = nil
    var processQueue:DispatchQueue!              = nil
    
    var isGray:Bool!                             = false
    var isGrayBuffer: MTLBuffer!                 = nil
    var blurStep: Float                          = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        initViewStyle()
        
        initMTLDevice()
        initMTLLayer()
        initBlurSlider()
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
        
        self.title = "渲染摄像头2"
        //self.navigationItem.leftBarButtonItem?.title = "返回"
        self.view.backgroundColor = UIColor.white
    }
    
    func initMTLDevice() {
        self.device = MTLCreateSystemDefaultDevice()
        if !MPSSupportsMTLDevice(self.device) {
            print("该设备不支持MetalPerformanceShaders!")
        }
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
        metalLayer.borderColor  = UIColor.red.cgColor
        metalLayer.borderWidth  = 2.0
        self.view.layer.addSublayer(metalLayer)
    }
    
    func initBlurSlider() {
        let blurSlider = UISlider(frame: CGRect(origin: CGPoint(x: 50, y: 570), size: CGSize(width: 300, height: 20)))
        blurSlider.minimumValue = 0.0
        blurSlider.maximumValue = 50.0
        blurSlider.value        = 5.0
        blurSlider.isContinuous = true
        blurSlider.addTarget(self, action: #selector(sliderChange(sender:)), for: .valueChanged)
        self.view.addSubview(blurSlider)
    }
    
    @objc func sliderChange(sender: UISlider) {
        self.blurStep = sender.value
    }
    
    func initCommandQueue() {
        self.commandQueue = self.device.makeCommandQueue()
    }
    
    @objc func drawloop() {
        self.render()
    }
    
    func render() {
        let drawable = metalLayer.nextDrawable()
        let commandBuffer = commandQueue.makeCommandBuffer()
        let filter = MPSImageGaussianBlur(device: self.device, sigma: self.blurStep)
        filter.encode(commandBuffer: commandBuffer!, sourceTexture: self.texture!, destinationTexture: (drawable?.texture)!)
        commandBuffer?.present(drawable!)
        commandBuffer?.commit()
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
                try self.texture = textureLoader.newTexture(cgImage: (localImg!.cgImage)!, options: [:])
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
