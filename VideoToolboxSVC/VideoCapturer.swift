//
//  VideoCapturer.swift
//  VideoToolboxSVC
//
//  Created by joey on 2021/7/3.
//

import UIKit
import AVFoundation

protocol VideoCapturerDelegate: NSObject {
    func videoCapturer(_ videoCapturer: VideoCapturer, didOutput sampleBuffer: CMSampleBuffer)
}

class VideoCapturer: NSObject {
    
    var captureSession: AVCaptureSession = AVCaptureSession()
    var captureSessionPreset: AVCaptureSession.Preset = AVCaptureSession.Preset.medium
    
    var videoDevice: AVCaptureDevice?
    var videoInput: AVCaptureDeviceInput?
    var videoDataOutput = AVCaptureVideoDataOutput()
    var dataOutputSynchronizer: AVCaptureDataOutputSynchronizer?
    
    let videoOutputQueue = DispatchQueue(label: "video-process-serial-queue")
    
    weak var delegate: VideoCapturerDelegate?
    
    func prepare() {
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }
        
        if captureSession.canSetSessionPreset(captureSessionPreset) {
            captureSession.sessionPreset = captureSessionPreset
        }
        
        videoDevice = AVCaptureDevice.devices(for: .video).filter({ device in
            return device.position == .front
        }).first
        
        if let videoDevice = videoDevice {
            try? videoInput = AVCaptureDeviceInput(device: videoDevice)
            if let videoInput = videoInput, captureSession.canAddInput(videoInput) {
                videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
                videoDataOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
                if captureSession.canAddOutput(videoDataOutput) {
                    captureSession.addInput(videoInput)
                    captureSession.addOutput(videoDataOutput)
                }
            }
        }

    }
    
    func start(with delegate: VideoCapturerDelegate) {
        prepare()
        
        self.delegate = delegate
        self.captureSession.startRunning()
    }
}

extension VideoCapturer: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.videoCapturer(self, didOutput: sampleBuffer)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
}
