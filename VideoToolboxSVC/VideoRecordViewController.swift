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
        self.previewLayer?.videoGravity = .resizeAspectFill
        self.previewLayer?.frame = self.view.bounds
        self.view.layer.addSublayer(self.previewLayer!)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer?.frame = self.view.bounds
    }
    
    @IBAction func recordButtonDidTap(_ sender: Any) {
        videoCapturer?.start(with: self)
    }
}

extension VideoRecordViewController: VideoCapturerDelegate {
    func videoCapturer(_ videoCapturer: VideoCapturer, didOutput sampleBuffer: CMSampleBuffer) {
    }
}

