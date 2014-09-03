//
//  PreviewView.swift
//  FitPlus
//
//  Created by Giancarlo Daniele on 9/3/14.
//  Copyright (c) 2014 Giancarlo Daniele. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    override class func layerClass() -> AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var session : AVCaptureSession? {
        get {
            var layer : AVCaptureVideoPreviewLayer = self.layer as AVCaptureVideoPreviewLayer
            return layer.session
        }
        set {
            var layer : AVCaptureVideoPreviewLayer = self.layer as AVCaptureVideoPreviewLayer
            layer.session = newValue
        }
    }
}