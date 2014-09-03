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
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var snapButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var timeLimitButton: UIButton!
    
    var sessionQueue : dispatch_queue_t?
    var session : AVCaptureSession?
    var videoDeviceInput : AVCaptureDeviceInput?
    var videoDevice : AVCaptureDevice?
    var movieFileOutput : AVCaptureMovieFileOutput?
    var stillImageOutput : AVCaptureStillImageOutput?
    var backgroundRecordingId : UIBackgroundTaskIdentifier?
    var deviceAuthorized : Bool?
    
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
        var session : AVCaptureSession = AVCaptureSession.alloc()
        self.session = session
        
//        TODO : Set up preview
        
        self.checkForAuthorizationStatus()
        
//        It's not safe to mutate an AVCaptureSession from multiple threads at the same time. Here, we're creating a sessionQueue so that the main thread is not blocked when AVCaptureSetting.startRunning is called.
        var queue : dispatch_queue_t = dispatch_queue_create("sesion queue", DISPATCH_QUEUE_SERIAL);
        self.sessionQueue = queue
        
        dispatch_async(queue, { () -> Void in
            self.backgroundRecordingId = UIBackgroundTaskInvalid
            var error : NSError?
                        
            
        })
        

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /* In a storyboard-based application, you will often want to do a little preparation before navigation    */
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    override func viewDidAppear(animated: Bool) {
        
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
    
//    MARK : Utilities
    class func deviceWithMediaTypeAndPosition(mediaType: NSString, position: AVCaptureDevicePosition) -> AVCaptureDevice {
        return AVCaptureDevice.alloc();
    }
    
}