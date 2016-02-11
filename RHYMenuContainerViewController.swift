//
//  RHYMenuContainerViewController.swift
//  rsk-hybrid
//
//  Created by Paul Von Schrottky on 3/17/15.
//  Copyright (c) 2015 Roshka. All rights reserved.
//

import UIKit
import QuartzCore

class RSKMenuContainerViewController: UIViewController {
    
    var isOpen = false
    var enabled: Bool {
        set {
            panGestureRecognizer?.enabled = enabled
        }
        get {
            return panGestureRecognizer!.enabled
        }
    }
    var openMargin = 50
    var panGestureRecognizer: UIPanGestureRecognizer?
    var menuViewController: UIViewController?
    var centerNavigationController: UINavigationController?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!;
    }
    
    init(leftViewController: UIViewController, mainViewController: UIViewController) {
        self.menuViewController = leftViewController
        self.centerNavigationController = UINavigationController(rootViewController:mainViewController)
        super.init(nibName: nil, bundle: nil)
    }
    
    init(leftViewController: UIViewController, mainViewController: UIViewController, overhang: Int) {
        self.menuViewController = leftViewController
        self.centerNavigationController = UINavigationController(rootViewController:mainViewController)
        self.openMargin = overhang
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        // Add the menu and center screens as children of this parent view controller.
        self.view.addSubview(self.menuViewController!.view)
        addChildViewController(self.menuViewController!)
        self.menuViewController!.didMoveToParentViewController(self)
        self.view.addSubview(self.centerNavigationController!.view)
        addChildViewController(self.centerNavigationController!)
        self.centerNavigationController!.didMoveToParentViewController(self)
        
        
        // Give the center screen a shadow.
        //        self.centerNavigationController!.view.layer.shadowOpacity = 0.8;
        //        self.centerNavigationController!.view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
        
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        self.centerNavigationController!.view.addGestureRecognizer(self.panGestureRecognizer!)
        self.panGestureRecognizer!.enabled = enabled
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // #pragma mark UIGestureRecognizerDelegate
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        
        let width = self.view.bounds.size.width
        
        switch(recognizer.state) {
            
        case .Changed:
            
            // translationInView gives the offset since the gesture started, or since setTranslation is last called.
            // Here we only allow the content to slide if it doesn't go too far left or right.
            let newPosition = recognizer.view!.center.x + recognizer.translationInView(self.view).x
            let isNotTooFarLeft = newPosition >= (width / 2)
            let isNotTooFarRight = newPosition <= width + (width / 2) - CGFloat(openMargin)
            if isNotTooFarLeft && isNotTooFarRight {
                recognizer.view!.center.x = newPosition
            }
            
            // This resets the value of translationInView to zero
            recognizer.setTranslation(CGPointZero, inView: self.view)
        case .Ended:
            
            // Animate the side panel open or closed based on whether the view has moved more or less than halfway
            // accross the screen.
            let hasMovedGreaterThanHalfway = recognizer.view!.center.x > width
            if hasMovedGreaterThanHalfway {
                openMenu(true)
            } else {
                closeMenu(true)
            }
            
        default:
            break
        }
    }
    
    
    // #pragma mark Other functions
    
    func openMenu(animated: Bool) {
        UIView.animateWithDuration(animated ? 0.5 : 0, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.centerNavigationController!.view.frame.origin.x = self.view.bounds.size.width - CGFloat(self.openMargin)
            }, completion: { (value: Bool) in
                self.isOpen = true
        })
    }
    
    func closeMenu(animated: Bool) {
        UIView.animateWithDuration(animated ? 0.5 : 0, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.centerNavigationController!.view.frame.origin.x = 0
            }, completion: { (value: Bool) in
                self.isOpen = false
        })
    }
    
    func toggleMenu(animated: Bool) {
        if isOpen == true {
            closeMenu(animated)
        } else {
            openMenu(animated)
        }
    }
    
    
}

