//
//  SampleBufferPlayerView.swift
//  VideoToolboxSVC
//
//  Created by joey on 2021/7/3.
//

import UIKit
import AVFoundation
import CoreMedia

class SampleBufferPlayerView: UIView {
    
    var playerLayer:AVSampleBufferDisplayLayer = AVSampleBufferDisplayLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = self.bounds
    }

    func present(_ sampleBuffer: CMSampleBuffer) {
        /**
         CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(videoFrame.sampleBuffer, YES);
         CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
         CFDictionarySetValue(dict, kCMSampleAttachmentKey_DoNotDisplay, kCFBooleanTrue);
         */
        playerLayer.enqueue(sampleBuffer)
        if playerLayer.status == .failed {
            playerLayer.flush()
            playerLayer.enqueue(sampleBuffer)
        }
        
        if let error = playerLayer.error {
            print("player layer encountered an error: \(error)")
        }
    }
}
