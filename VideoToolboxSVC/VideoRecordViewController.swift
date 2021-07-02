//
//  ViewController.swift
//  VideoToolboxSVC
//
//  Created by joey on 2021/7/2.
//

import UIKit
import AVFoundation

class VideoRecordViewController: UIViewController {
    
    var playerView: SampleBufferPlayerView?
    var videoCapturer: VideoCapturer?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerView = SampleBufferPlayerView(frame: self.view.frame)
        videoCapturer = VideoCapturer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerView?.frame = self.view.frame
    }
    
    @IBAction func recordButtonDidTap(_ sender: Any) {
        videoCapturer?.start(with: self)
    }
}

extension VideoRecordViewController: VideoCapturerDelegate {
    func videoCapturer(_ videoCapturer: VideoCapturer, didOutput sampleBuffer: CMSampleBuffer) {
        playerView?.present(sampleBuffer)
    }
}

