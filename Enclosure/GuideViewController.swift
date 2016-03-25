//
//  GuideViewController.swift
//  Enclosure
//
//  Created by Kedan Li on 3/24/16.
//  Copyright © 2016 TakeFive Interactive. All rights reserved.
//

import UIKit

class GuideViewController: UIViewController {
    @IBOutlet weak var info: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        super.touchesBegan(touches, withEvent: event)
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.alpha = 0
        }) { (finish) -> Void in
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        }
    }
}
