//
//  CameraViewController.swift
//  FitPlus
//
//  Created by Giancarlo Daniele on 8/22/14.
//  Copyright (c) 2014 Giancarlo Daniele. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary

class CameraViewController: UIViewController {
    @IBOutlet weak var snapButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var timeLimitButton: UIButton!
    @IBOutlet weak var previewView: PreviewView!
    
    var sessionQueue : dispatch_queue_t?
    var session : AVCaptureSession?
    var videoDeviceInput : AVCaptureDeviceInput?
    var videoDevice : AVCaptureDevice?
    var movieFileOutput : AVCaptureMovieFileOutput?
    var stillImageOutput : AVCaptureStillImageOutput?
    var backgroundRecordingId : UIBackgroundTaskIdentifier?
    var deviceAuthorized : Bool?
    
    var sessionRunningAndDeviceAuthorized : Bool {
        get {
            return ((self.session?.running)! && (self.deviceAuthorized != nil))
        }
    }
    
    let CONTROL_NORMAL_COLOR : UIColor?
    let CONTROL_HIGHLIGHT_COLOR : UIColor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.snapButton.layer.cornerRadius = 4
        self.flipButton.layer.cornerRadius = 4
        self.timeLimitButton.layer.cornerRadius = 4
        
        self.snapButton.clipsToBounds = true
        self.flipButton.clipsToBounds = true
        self.timeLimitButton.clipsToBounds = true
        
        //        Create the AV Session!
        var session : AVCaptureSession = AVCaptureSession()
        self.session = session
        
        self.previewView.session = session
        
        self.checkForAuthorizationStatus()
        
        //        It's not safe to mutate an AVCaptureSession from multiple threads at the same time. Here, we're creating a sessionQueue so that the main thread is not blocked when AVCaptureSetting.startRunning is called.
        var queue : dispatch_queue_t = dispatch_queue_create("sesion queue", DISPATCH_QUEUE_SERIAL);
        self.sessionQueue = queue
        
        dispatch_async(queue, { () -> Void in
            self.backgroundRecordingId = UIBackgroundTaskInvalid
            var error : NSError?
            
            var videoDevice : AVCaptureDevice = CameraViewController.deviceWithMediaTypeAndPosition(AVMediaTypeVideo, position: AVCaptureDevicePosition.Back)
            var videoDeviceInput : AVCaptureDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(videoDevice, error: &error) as AVCaptureDeviceInput
            
            if ((error) != nil) {
                println("Error executing videoDevice")
            }
            
            self.session?.beginConfiguration()
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                self.videoDevice = videoDeviceInput.device
            }
            
            var stillImageOutput : AVCaptureStillImageOutput = AVCaptureStillImageOutput()
            
            if session.canAddOutput(stillImageOutput) {
                stillImageOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
                session.addOutput(stillImageOutput)
                self.stillImageOutput = stillImageOutput
            }
            self.session?.commitConfiguration()
            
//            TODO: Optional here, dispatch another thread to set up camera controls
        })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        dispatch_async(self.sessionQueue, { () -> Void in
//            TODO: Add observers
            self.session!.startRunning()
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        dispatch_async(self.sessionQueue, { () -> Void in
            //            TODO: Remove observers
            self.session!.stopRunning()
        })
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    //    MARK : Utilities
    class func deviceWithMediaTypeAndPosition(mediaType: NSString, position: AVCaptureDevicePosition) -> AVCaptureDevice {
        var devices : NSArray = AVCaptureDevice.devicesWithMediaType(mediaType)
        var captureDevice : AVCaptureDevice = devices.firstObject as AVCaptureDevice
        
        for device in devices {
            let device = device as AVCaptureDevice
            if device.position == position {
                captureDevice = device
                break
            }
        }
        return captureDevice
    }
    
    func checkForAuthorizationStatus() {
        var mediaType : NSString = AVMediaTypeVideo;
        AVCaptureDevice .requestAccessForMediaType(mediaType, completionHandler: { (granted) -> Void in
            if (granted) {
                self.deviceAuthorized = true
            } else {
                dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                    UIAlertView(title: "FitPlus", message: "FitPlus doesn't have permission to use the camera!", delegate: self, cancelButtonTitle: "OK").show()
                    self.deviceAuthorized = false
                })
            }
        })
    }
    
//    MARK: UI

    
}