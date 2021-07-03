//
//  ViewController.swift
//  VideoToolboxSVC
//
//  Created by joey on 2021/7/2.
//

import UIKit
import AVFoundation

class VideoRecordViewController: UIViewController {
    
    @IBOutlet weak var recordButton: UIButton!
    var videoCapturer: VideoCapturer?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var isRecording = false
    var videoEncoder: VTEncoder?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoCapturer = VideoCapturer()
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.videoCapturer!.captureSession)
        self.view.layer.insertSublayer(self.previewLayer!, below: self.recordButton.layer)
        self.previewLayer?.videoGravity = .resizeAspectFill
        self.previewLayer?.frame = self.view.bounds
        videoEncoder = VTEncoder(exportPath: "", duration: 10)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer?.frame = self.view.bounds
    }
    
    @IBAction func recordButtonDidTap(_ sender: Any) {
        if isRecording {
            isRecording = false
            videoCapturer?.stop()
            videoEncoder?.stop()
            recordButton.setTitle("Record", for: .normal)
        } else {
            isRecording = true
            videoEncoder?.prepareVideoToolBox()
            videoCapturer?.start(with: self)
            recordButton.setTitle("Stop recording", for: .normal)
        }
    }
}

extension VideoRecordViewController: VideoCapturerDelegate {
    func videoCapturer(_ videoCapturer: VideoCapturer, didOutput sampleBuffer: CMSampleBuffer) {
        videoEncoder?.encode(sampleBuffer)
    }
}

