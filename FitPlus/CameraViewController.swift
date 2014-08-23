//
//  CameraViewController.swift
//  FitPlus
//
//  Created by Giancarlo Daniele on 8/22/14.
//  Copyright (c) 2014 Giancarlo Daniele. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var snapButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var timeLimitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        setupCameraView()
    }
    
//    MARK: UI Positioning helpers

//    Sets auto layout attributes of cameraView UI elements
    func setupCameraView() {
        cameraView.frame = UIScreen.mainScreen().applicationFrame
    }
}