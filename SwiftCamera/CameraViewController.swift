//
//  CameraViewController.swift
//  SwiftCamera
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
        self.timeLimitButton.layer.opacity = 0
        
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
    
    override func viewWillAppear(animated: Bool) {
        dispatch_async(self.sessionQueue, { () -> Void in
            self.addNotificationObservers()
            self.session!.startRunning()
        })
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        dispatch_async(self.sessionQueue, { () -> Void in
            self.session!.stopRunning()
            self.removeNotificationObservers()
        })
        super.viewDidDisappear(animated)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
//    MARK: Device Configuration
    class func setFlashMode(flashMode: AVCaptureFlashMode, device: AVCaptureDevice) {
        if device.flashAvailable && device.isFlashModeSupported(flashMode) {
            var error : NSError?
            if device.lockForConfiguration(&error) {
                device.flashMode = flashMode
                device.unlockForConfiguration()
            } else {
                println("Error turning on flash")
            }
        }
    }
    
    func focus(focusMode: AVCaptureFocusMode, exposureMode: AVCaptureExposureMode, point: CGPoint, monitorSubjectAreaChange: Bool) {
        dispatch_async(self.sessionQueue, { () -> Void in
            var device : AVCaptureDevice = self.videoDevice!
            var error : NSError?
            if device.lockForConfiguration(&error) {
                if device.focusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusMode = focusMode
                    device.focusPointOfInterest = point
                }
                if device.exposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposureMode = exposureMode
                    device.exposurePointOfInterest = point
                }
                device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } else {
                println("Error setting focus")
            }
        })
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
                    UIAlertView(title: "SwiftCamera", message: "SwiftCamera doesn't have permission to use the camera!", delegate: self, cancelButtonTitle: "OK").show()
                    self.deviceAuthorized = false
                })
            }
        })
    }
    
//    MARK: UI
    
//    MARK: Actions
    @IBAction func takeStillImage(sender: AnyObject) {
        dispatch_async(self.sessionQueue, { () -> Void in
            var layer : AVCaptureVideoPreviewLayer = self.previewView.layer as AVCaptureVideoPreviewLayer
            self.stillImageOutput?.connectionWithMediaType(AVMediaTypeVideo).videoOrientation = layer.connection.videoOrientation
            
//            For still images, let's set flash to auto
            CameraViewController.setFlashMode(AVCaptureFlashMode.Auto, device: self.videoDevice!)
            
//            Capture the image
            self.stillImageOutput?.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput?.connectionWithMediaType(AVMediaTypeVideo), completionHandler: { (imageDataSampleBuffer, error) -> Void in
                if ((imageDataSampleBuffer) != nil) {
                    var imageData : NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    var image : UIImage = UIImage(data: imageData)
                    ALAssetsLibrary().writeImageToSavedPhotosAlbum(image.CGImage, orientation: ALAssetOrientation.fromRaw(image.imageOrientation.toRaw())!, completionBlock: nil)
                }
            })
        })
    }

    @IBAction func flipCamera(sender: AnyObject) {
        self.snapButton.enabled = false
        self.flipButton.enabled = false
        self.timeLimitButton.enabled = false
        
        dispatch_async(self.sessionQueue, { () -> Void in
            var currentVideoDevice : AVCaptureDevice = self.videoDevice!
            var preferredPosition : AVCaptureDevicePosition = AVCaptureDevicePosition.Unspecified
            var currentPosition : AVCaptureDevicePosition = currentVideoDevice.position
            
            switch (currentPosition)
            {
            case AVCaptureDevicePosition.Unspecified:
                preferredPosition = AVCaptureDevicePosition.Back
                break;
            case AVCaptureDevicePosition.Back:
                preferredPosition = AVCaptureDevicePosition.Front
                break;
            case AVCaptureDevicePosition.Front:
                preferredPosition = AVCaptureDevicePosition.Back
                break;
            }
            
            var newVideoDevice : AVCaptureDevice = CameraViewController.deviceWithMediaTypeAndPosition(AVMediaTypeVideo, position: preferredPosition)
            var newVideoDeviceInput : AVCaptureDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(newVideoDevice, error: nil) as AVCaptureDeviceInput
            
            self.session!.beginConfiguration()
            
            self.session!.removeInput(self.videoDeviceInput)
            
            if self.session!.canAddInput(newVideoDeviceInput) {
                NSNotificationCenter.defaultCenter().removeObserver(self, name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: currentVideoDevice)
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "subjectAreaDidChance", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: newVideoDevice)
                
                self.session!.addInput(newVideoDeviceInput)
                self.videoDeviceInput = newVideoDeviceInput
                self.videoDevice = newVideoDeviceInput.device
            } else {
                self.session!.addInput(self.videoDeviceInput)
            }
            self.session!.commitConfiguration()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.snapButton.enabled = true
                self.flipButton.enabled = true
                self.timeLimitButton.enabled = true
//                TODO: Implement Video features for iOS 8 (e.g. white bal, ISO, etc)
            })
        
        })
    }
    
//    MARK: Observers :)
    func subjectAreaDidChange(notification: NSNotification) {
        var devicePoint : CGPoint = CGPoint(x: 0.5, y: 0.5)
        self.focus(AVCaptureFocusMode.ContinuousAutoFocus, exposureMode: AVCaptureExposureMode.ContinuousAutoExposure, point: devicePoint, monitorSubjectAreaChange: false)
        
    }
    
    func addNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "subjectAreaDidChange", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.videoDevice)
    }
    
    func removeNotificationObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.videoDevice)
    }
    
}