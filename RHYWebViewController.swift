//
//  RHYWebViewController.swift
//  rHybridDemo
//
//  Created by Paul Von Schrottky on 7/10/15.
//  Copyright (c) 2015 Roshka. All rights reserved.
//

import UIKit
import WebKit
import Foundation

typealias OnLoadListener = (webView: UIWebView) -> Void

class RHYWebViewController: UIViewController, UIWebViewDelegate {
    
    var menuContainerViewController: RSKMenuContainerViewController!
    var activityIndictator: MBProgressHUD!
    var menuOverhang = 0
    var menuOverhangConstraint: NSLayoutConstraint?
    var HTMLFile: String!
    var uiWebView: UIWebView!
    var javaScripts: NSMutableArray!
    let statusBarView = UIView()
    var onLoadListeners = [OnLoadListener]()
    var uiWebViewNavigationBarConstraint : NSLayoutConstraint!
    var uiWebViewStatusBarConstraint : NSLayoutConstraint!
    var showNavigationBar: Bool = false
    var form: NSData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(self)
        
        // We set this to 'false' so that the contents of the web view uses the full height
        // of the web view.
        self.automaticallyAdjustsScrollViewInsets = false;
        
        
        // Set the default status bar text color (remember to set 'View controller-based status bar' to 'NO' in the target's plist).
        UIApplication.sharedApplication().setStatusBarStyle(.Default, animated:false)
        
        // Hide the navigation bar (we have our own navigation bar in HTML).
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Make the array of javascripts to inject into every page.
        let bundle = NSBundle.mainBundle()
        javaScripts = NSMutableArray()
        for jsFile in ["rhy", "rhy-ios", "rsk-utils"] {
            var path = NSBundle.mainBundle().bundlePath
            path = path.stringByAppendingString("/\(jsFile).js")
            let javaScript = try! String(contentsOfURL: NSURL(fileURLWithPath: path), encoding: NSUTF8StringEncoding)
            javaScripts.addObject(javaScript)
        }
        
        // Make a web view and add it to the screen.
        self.uiWebView = UIWebView()
        
        // Set the web view to use the full width except if this screen is the menu screen, which has a right margin.
        // Also, full height (except for the status bar margin).
        self.uiWebView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.uiWebView)
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .Left, relatedBy: .Equal, toItem: self.uiWebView, attribute: .Left, multiplier: 1, constant: 0))
        self.menuOverhangConstraint = NSLayoutConstraint(item: self.uiWebView, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 0)
        self.view.addConstraint(self.menuOverhangConstraint!)
        
        self.statusBarView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.statusBarView)
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[statusBarView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["statusBarView": self.statusBarView]))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            "V:|[statusBarView(20)][uiWebView]|",
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: ["uiWebView": self.uiWebView, "statusBarView": self.statusBarView]))
        
        // This allows the keyboard to be shown programatically using the 'autofocus' HTML input tag attribute.
        self.uiWebView.keyboardDisplayRequiresUserAction = false
        
        // Assign its delegate to us so we can catch events.
        self.uiWebView.delegate = self
        
        // Do not display vertical scroll bars.
        self.uiWebView.scrollView.showsVerticalScrollIndicator = false;
        
        // Remove bounces from the web view.
        self.uiWebView.scrollView.bounces = false;
        
        // Disable blue highlighting of phone numbers, etc. by the web view.
        self.uiWebView.dataDetectorTypes = UIDataDetectorTypes.None
        
        // If this screen was passed a HTML page, open it. If not, open the default screen.
        if (HTMLFile == nil) {
            loadWebViewWithHTMLFile(self.uiWebView, file: "index.html")
        } else {
            loadWebViewWithHTMLFile(self.uiWebView, file: HTMLFile)
        }
        
//        self.uiWebViewNavigationBarConstraint = NSLayoutConstraint(item: self.uiWebView, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: 64)
        self.uiWebViewStatusBarConstraint = NSLayoutConstraint(item: self.uiWebView, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: 20)
        
//        if(self.showNavigationBar) {
//            self.view.addConstraint(self.uiWebViewNavigationBarConstraint)
//            self.navigationController?.setNavigationBarHidden(false, animated: true)
//        } else {
//            self.view.addConstraint(self.uiWebViewStatusBarConstraint)
//            self.navigationController?.setNavigationBarHidden(true, animated: true)
//        }
        
        self.view.layoutIfNeeded()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
//        if(self.showNavigationBar) {
//            self.view.addConstraint(self.uiWebViewNavigationBarConstraint)
//            self.navigationController?.setNavigationBarHidden(false, animated: false)
//        } else {
//            self.view.addConstraint(self.uiWebViewStatusBarConstraint)
//            self.navigationController?.setNavigationBarHidden(true, animated: false)
//        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // When a screen is popped, we want to set the UIStatusBar color so that it matches the previous screen.
        // Note that this method, viewWillDisappear, is called on the screen being popped.
        // isMovingFromParentViewController returns true on the screen being popped, and topViewController already
        // is the previous screen.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        uiWebView.stringByEvaluatingJavaScriptFromString("Rhy.iOS.setStatusBarColor()")
    }
    
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
    Load the given file in the given web view.
    
    @param webView the web view to load the file into
    @param file the file to load into the web view
    */
    func loadWebViewWithHTMLFile(webView:UIWebView, file:String) {
        let baseURL = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath);
        let relativePath = "www/\(file)"
        let fileURL = NSURL(string: relativePath, relativeToURL: baseURL);
        let URLRequest = NSURLRequest(URL: fileURL!);
        webView.loadRequest(URLRequest)

    }
    
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        // If the request uses our URL Scheme, this call corresponds to us.
        if request.URL!.scheme == "rhybrid" {
            
            // Get the parameters passes as query parameters from the URL.
            var query = request.URL!.query!.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
//            var optionsJSON = query.componentsSeparatedByString("=")[1]
//            let params = RHYUtils.objectForJSONString(JSONString: optionsJSON) as! NSDictionary
            let params = RHYUtils.dictionaryFromQueryParams(query)
            print("params of\(self.HTMLFile): \(params)")
            
            
            if let keys = params["getValuesForKeys"] as? NSArray {
                
                var response = NSMutableDictionary()
                let timestamp = RHYUtils.rfc822DateAsEscapedString()
                let mobileID = UIDevice.currentDevice().identifierForVendor!.UUIDString
                let clientSecret = ""
                
                for key in keys {
                    if key as! NSString == "MOBILE_ID" {
                        response[key as! NSString] = mobileID
                    }
                    if key as! NSString == "TIMESTAMP" {
                        response[key as! NSString] = RHYUtils.rfc822DateAsEscapedString()
                    }
                }
                
                // Return the JavaScript {object} whose values are the requested parameters.
                if let JSONResponse = response.JSONString_rsk() {
                    webView.stringByEvaluatingJavaScriptFromString("Rhy.iOS.response = JSON.parse('\(JSONResponse)')")
                }
            }
            
            if params["setiOSStatusBarColor"] != nil {
                
                // Add UIViewControllerBasedStatusBarAppearance YES to Info.plist
                
                let red = params["setiOSStatusBarColor"]?.floatValue
                let redValue:CGFloat = CGFloat(red!) / 255.0
                
                let green = params["green"]?.floatValue
                let greenValue:CGFloat = CGFloat(green!) / 255.0
                
                let blue = params["blue"]?.floatValue
                let blueValue:CGFloat = CGFloat(blue!) / 255.0
                
                var averageColor = (redValue + greenValue + blueValue) / 3.0;
                
                // Set the status bar text color (either light or dark).
                if averageColor > 0.6 {
                    UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: false);
                } else {
                    UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false);
                }
                
                // Set the status bar background.
                let color = UIColor(red: redValue, green: greenValue, blue: blueValue, alpha: 1.0)
                self.statusBarView.backgroundColor = UIColor(red: redValue, green: greenValue, blue: blueValue, alpha: 1.0)
            }
            
            if let URLScheme = params["showActivityIndicator"] as? String {
                if let menuContainerVC = self.menuContainerViewController {
                    menuContainerVC.enabled = false
                }
                
                self.activityIndictator = MBProgressHUD(view:self.view)
                self.activityIndictator.animationType = MBProgressHUDAnimationFade
                
                self.activityIndictator.labelText = "Loading..."
                self.activityIndictator.detailsLabelText = "please wait..."
                
                if let title = params["title"] as? String {
                    self.activityIndictator.labelText = title;
                }
                if let message = params["message"] as? String {
                    self.activityIndictator.detailsLabelText = message;
                }
                
                self.view.addSubview(self.activityIndictator)
                self.activityIndictator.show(true)
            }
            
            if let URLScheme = params["hideActivityIndicator"] as? String {
                if let menuContainerVC = self.menuContainerViewController {
                    menuContainerVC.enabled = true
                }
                self.activityIndictator.hide(true)
            }
            
            if let newScreen = params["newScreen"] as? String {
                if newScreen.containsString(".html") {
                    let nextScreen = self.storyboard!.instantiateViewControllerWithIdentifier("RHYWebViewControllerStoryboardID") as! RHYWebViewController
//                    let showStatusBar = params["showNavigationBar"] as? String
                    nextScreen.HTMLFile = newScreen
                    nextScreen.menuContainerViewController = self.menuContainerViewController
                    
//                    if(showStatusBar == "true") {
//                        nextScreen.showNavigationBar = true;
////                        self.navigationController?.setNavigationBarHidden(false, animated: true)
////                        nextScreen.view.addConstraint(self.uiWebViewNavigationBarConstraint)
//                    } else {
//                        nextScreen.showNavigationBar = false;
////                        self.navigationController?.setNavigationBarHidden(true, animated: true)
////                        nextScreen.view.addConstraint(self.uiWebViewStatusBarConstraint)
//                    }
                    
                    self.navigationController?.pushViewController(nextScreen, animated: true)
                } else {
                    var nextScreen = self.storyboard!.instantiateViewControllerWithIdentifier(newScreen)
//                    self.navigationController?.pushViewController(nextScreen, animated: true)
                    self.navigationController?.pushViewController(nextScreen, animated: true)
                }
            }
            
            if params["popScreen"] != nil {
                let screens = params["popScreen"]?.integerValue
                let totalScreens = self.navigationController?.viewControllers.count
                let destinationViewControllerIndex = totalScreens! - screens! - 1    // Offset 0 indexing.
                let destinationViewController = self.navigationController?.viewControllers[destinationViewControllerIndex] as! RHYWebViewController

                self.navigationController?.popToViewController(destinationViewController, animated: true)
                if let callback = params["callback"] as? String {
                    destinationViewController.uiWebView.stringByEvaluatingJavaScriptFromString("\(callback)()")
                }
            }
            
            if let menuHTMLFile = params["createMenu"] as? String {
                
                // We make a new screen for the menu HTML page.
                let menuViewController = RHYWebViewController()
                menuViewController.HTMLFile = menuHTMLFile
                let overhang = params["menuMargin"] as! Int
                menuViewController.view.frame = CGRectMake(0, 0, menuViewController.view.frame.size.width - CGFloat(overhang), menuViewController.view.frame.size.height)
//                menuViewController.addOnLoadListener({(webView: UIWebView) in
//                    let newWidth = webView.frame.size.width - CGFloat(overhang)
//                    let javaScript = "document.querySelector('meta[name=viewport]').setAttribute('content', 'width=\(newWidth);', false);"
//                    webView.stringByEvaluatingJavaScriptFromString(javaScript)
//                })

                
                // We make a new screen for the center HTML page (and wrap it in a navigation controller).
                let centerViewController = RHYWebViewController()
                centerViewController.HTMLFile = params["openFileName"] as! String
            
                

                
                // Make the menu container.
                var a = UIViewController()
                a.view.backgroundColor = UIColor.redColor()
                a.navigationController?.setNavigationBarHidden(true, animated: false)
                a.automaticallyAdjustsScrollViewInsets = false;
                self.menuContainerViewController = RSKMenuContainerViewController(leftViewController: menuViewController, mainViewController: centerViewController, overhang: overhang)
                
                // Setting this is important to fix the status bar for the menu.
                self.menuContainerViewController.automaticallyAdjustsScrollViewInsets = false
                
                // Each of the screens (menu and center) needs a reference to the menu container.
                menuViewController.menuContainerViewController = self.menuContainerViewController
                centerViewController.menuContainerViewController = self.menuContainerViewController
                
                // Show the menu container and its contents.
                self.navigationController?.pushViewController(self.menuContainerViewController, animated: true)
            }
            
            if let menuOverhang = params["menuOverhang"] as? Int {
                
                // We reduce the menu screen web view's width by the menu overhang.
                var menuVC = self.menuContainerViewController.menuViewController as! RHYWebViewController
                
                menuVC.view.removeConstraint(menuVC.menuOverhangConstraint!)
                menuVC.menuOverhangConstraint = NSLayoutConstraint(item: menuVC.uiWebView, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: menuVC.view, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: -CGFloat(menuOverhang))
                menuVC.view.addConstraint(menuVC.menuOverhangConstraint!)
                
                // Update the menu screen web view content's width to its new width.
                var javaScript = "document.querySelector('meta[name=viewport]').setAttribute('content', 'width=\(menuVC.uiWebView.frame.size.width - CGFloat(menuOverhang));', false);"
                menuVC.uiWebView.stringByEvaluatingJavaScriptFromString(javaScript)
                
                // Update the menu container's menu overhang to refect the change.
                self.menuContainerViewController.openMargin = menuOverhang
            }
            
            
            if let key = params["updateAppConfigKey"] as? String {
                
                // Update the app config with the given key and value.
                let appConfig = NSUserDefaults.standardUserDefaults().objectForKey(RHY_CONFIG_KEY) as! NSDictionary
                let appConfigMutable = appConfig.mutableCopy() as! NSMutableDictionary
                appConfigMutable.setValue(params[key], forKey: key)
                NSUserDefaults.standardUserDefaults().setObject(appConfigMutable, forKey: "RSK_APP_CONFIG")
            }
            
            if params["toggleMenu"] != nil {
                self.menuContainerViewController?.toggleMenu(true)
            }
            
            if let fileName = params["openMenuOption"] as? String {
                
                // Get the navigation controller of the right stack of screens.
                var rightNavigationController = self.menuContainerViewController.menuViewController as! UINavigationController
                
                // Get the view controller that is currently showing from the right stack of screens.
                var rightViewController = rightNavigationController.viewControllers.last!
                
                // If the selected option is already open, don't do anything.
                let isHTMLScreen                    = fileName.hasSuffix(".html")
                let isHTMLScreenAlreadyOpen         = rightViewController is RHYWebViewController && (rightViewController as! RHYWebViewController).HTMLFile == fileName
                let isNativeScreenAlreadyOpen       = !(rightViewController is RHYWebViewController)
                let isNativeScreenClassAlreadyOpen  = rightViewController.dynamicType.description().hasSuffix(fileName)
                
                if isHTMLScreen && (!isHTMLScreenAlreadyOpen || isNativeScreenAlreadyOpen) {
                    
                    // Open the option's screen.
                    var nextScreen = RHYWebViewController()
                    nextScreen.HTMLFile = fileName
                    nextScreen.menuContainerViewController = self.menuContainerViewController
                    rightNavigationController.viewControllers = [nextScreen]
                    
                } else if !isNativeScreenClassAlreadyOpen {
                    
                    // Open the option's screen. First get the view controller that corresponds to the
                    // given file, instantiate it, and open it.
                    var appName: String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as! String
                    appName = appName.stringByReplacingOccurrencesOfString("-", withString: "_")
                    var anyobjectype : AnyObject.Type = NSClassFromString("\(appName).\(fileName)")!
                    var nsobjectype : NSObject.Type = anyobjectype as! NSObject.Type
                    var nextScreen: RHYViewController = nsobjectype.init() as! RHYViewController
                    nextScreen.menuContainerViewController = self.menuContainerViewController
                    rightNavigationController.viewControllers = [nextScreen]
                }
                
                // Close the menu.
                self.menuContainerViewController.closeMenu(true)
            }
            
            if let number = params["callPhone"] as? String {
                var URLScheme = "tel"
                if params["showPrompt"] != nil {
                    URLScheme = "telprompt"
                }
                let telefoneURL = NSURL(string: "\(URLScheme)://\(number)")
                if UIApplication.sharedApplication().canOpenURL(telefoneURL!) {
                    UIApplication.sharedApplication().openURL(telefoneURL!)
                } else {
                    // If we don't execute the UIAlertView through the GCD dispatch main queue,
                    // the DOM element in the web view below the UIAlertView receives an extra
                    // touchstart JavaScript event (for some buggy reason), which can be
                    // problematic.
                    // Adding the UIAlertView back onto the main queue via dispatch_async guarantees
                    // that it the alert view will be executed after the current method finishes.
                    // See: http://www.raywenderlich.com/79149/grand-central-dispatch-tutorial-swift-part-1
                    dispatch_async(dispatch_get_main_queue()) {
                        UIAlertView(title: params["title"] as! String?,
                            message: params["message"] as! String?,
                            delegate: nil,
                            cancelButtonTitle: params["okButtonTitle"] as! String?).show()
                    }
                }
            }
            
            if let URLString = params["openInBrowser"] as? String {
                let URL = NSURL(string: URLString)
                UIApplication.sharedApplication().openURL(URL!)
            }
            
            if params["isAppInstalled"] != nil {
                let options = params["IOS"] as! NSDictionary
                let URLScheme = options["URLScheme"] as! NSString
                let application = UIApplication.sharedApplication()
                let URLSchemeString = options["URLScheme"] as! NSString
                let URLString = "\(URLSchemeString)://"
                let URL = NSURL(string: URLString)
                var response: NSString;
                if application.canOpenURL(URL!) {
                    response = "true"
                } else {
                    response = "false"
                }
                webView.stringByEvaluatingJavaScriptFromString("Rhy.iOS.response = \(response)")
            }
            
            if params["openApp"] != nil {
                let options = params["IOS"] as! NSDictionary
                let appID = options["appID"] as! NSString
                let URLScheme = options["URLScheme"] as! NSString
                let application = UIApplication.sharedApplication()
                let URLString = "\(URLScheme)://"
                var URL = NSURL(string: URLString)
                
                // If the app is not installed, change to the app's App Store URL.
                if application.canOpenURL(URL!) == false {
                    URL = NSURL(string: "itms://itunes.apple.com/app/id\(appID)")
                }
                
                // Open the URL.
                application.openURL(URL!)
            }
            
            if params["formFactor"] != nil {
                var formFactor: NSString
                // Note that this is better than using userInterfaceIdiom because this method will
                // still return iPad even for iPhone apps running on iPads.
                if (UIDevice.currentDevice().model.hasPrefix("iPad")) {
                    formFactor = "TABLET"
                } else {
                    formFactor = "SMARTPHONE"
                }
                webView.stringByEvaluatingJavaScriptFromString("Rhy.iOS.response = \"'\(formFactor)'\"")
            }
            
            if let key = params["getValueForKey"] as? String {
                
                var value = RHYValueForKey.getValueForKey(key) as String!
                
//                print(value!)
                if(value == nil) {
                    value = "null"
                }
                
                var json = (try? String(data: NSJSONSerialization.dataWithJSONObject([value], options: NSJSONWritingOptions(rawValue: 0)), encoding: NSUTF8StringEncoding)!)!
                json = json.substringWithRange(Range<String.Index>(start: json.startIndex.advancedBy(2), end: json.endIndex.advancedBy(-2)))
                
                webView.stringByEvaluatingJavaScriptFromString("Rhy.iOS.response = '\(json)'")
            }
            
            if let key = params["setValueForKey"] as? String {
                
                RHYValueForKey.setValueForKey(key, value: params["value"]!)
                
//                print(value!)
                
//                webView.stringByEvaluatingJavaScriptFromString("Rhy.iOS.response = '\(value!)'")
            }
            
            if params["showNavigationBar"] != nil {
                let enabled = params["showNavigationBar"] as! String!
                if(enabled == "true") {
                    self.navigationController!.setNavigationBarHidden(false, animated: false)
                    self.uiWebView.removeConstraint(self.uiWebViewStatusBarConstraint)
//                    self.uiWebView.addConstraint(self.uiWebViewNavigationBarConstraint)
                    
                    
                } else {
                    if let navigationController = self.navigationController {
                        navigationController.setNavigationBarHidden(true, animated: false)
                        self.uiWebView.removeConstraint(self.uiWebViewNavigationBarConstraint)
                        self.uiWebView.addConstraint(self.uiWebViewStatusBarConstraint)
                    }
                }
            }
            
            /**
             * PAGO DE SERVICIOS. (Sólo para EFICASH) Al final no se usa, eliminar al terminar.
             */
            if params["pay_form"] != nil {
                let nextScreen = RHYWebViewController()
                let showStatusBar = params["showNavigationBar"] as? String
                nextScreen.HTMLFile = "pago_servicios.html"
                
                if(showStatusBar == "true") {
                    nextScreen.showNavigationBar = true;
                    //                        self.navigationController?.setNavigationBarHidden(false, animated: true)
                    //                        nextScreen.view.addConstraint(self.uiWebViewNavigationBarConstraint)
                } else {
                    nextScreen.showNavigationBar = false;
                    //                        self.navigationController?.setNavigationBarHidden(true, animated: true)
                    //                        nextScreen.view.addConstraint(self.uiWebViewStatusBarConstraint)
                }
                
                self.navigationController?.pushViewController(nextScreen, animated: true)
            }
            
            if params["showAlert"] != nil {
                let message = params["showAlert"] as! String;
                var title : String? = params["title"] as? String
                var buttonText : String? = params["button_text"] as? String
                
                if(title == nil) {
                    title = "Mensaje";
                }
                
                if(buttonText == nil) {
                    buttonText = "Aceptar";
                }
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                
                alert.addAction(UIAlertAction(title: buttonText, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    if(params["callback"] != nil) {
                        let callback = params["callback"] as! String
                        self.uiWebView.stringByEvaluatingJavaScriptFromString("\(callback)()")
                    }
                }));
                
                self.presentViewController(alert, animated: true, completion: nil)
            }
            
            if params["logout"] != nil {
    
                let indexViewController = self.storyboard!.instantiateViewControllerWithIdentifier("RHYWebViewControllerStoryboardID") as! RHYWebViewController
                let loginViewController = self.storyboard!.instantiateViewControllerWithIdentifier("RHYWebViewControllerStoryboardID") as! RHYWebViewController
                indexViewController.HTMLFile = "index.html"
                loginViewController.HTMLFile = "login.html"
                
                navigationController!.setViewControllers([indexViewController, loginViewController], animated: true)
            }
            
            if params["showConfirmDialog"] != nil {
                let message = params["showConfirmDialog"] as! String;
                var title = "Mensaje"
                var buttonOk = "Aceptar"
                var buttonCancel = "Cancelar"
                
                if let passedTitle = params["title"] as? String {
                    title = passedTitle
                }
                
                if let passedButtonOk = params["buttonOk"] as? String {
                    buttonOk = passedButtonOk
                }
                
                if let passedButtonCancel = params["buttonCancel"] as? String {
                    buttonCancel = passedButtonCancel
                }
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                
                alert.addAction(UIAlertAction(title: buttonOk, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    if(params["callback"] != nil) {
                        let callback = params["callback"] as! String
                        self.uiWebView.stringByEvaluatingJavaScriptFromString("\(callback)()")
                    }
                }));
                
                alert.addAction(UIAlertAction(title: buttonCancel, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    debugPrint("cancelado")
                }));
                
                self.presentViewController(alert, animated: true, completion: nil)
            }
            
            // We handled JavaScript communication, so there is no page to be loaded.
            return false
        }
        
        // There was no JavaScript communication to handle, so go ahead and load the page.
        return true
    }
    
    func renderFormData(data: NSData) -> Void {
        let string = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
        var json = (try? String(data: NSJSONSerialization.dataWithJSONObject([string], options: NSJSONWritingOptions(rawValue: 0)), encoding: NSUTF8StringEncoding)!)!
        json = json.substringWithRange(Range<String.Index>(start: json.startIndex.advancedBy(2), end: json.endIndex.advancedBy(-2)))
        
        self.uiWebView.stringByEvaluatingJavaScriptFromString("renderForm(\"\(json)\")")
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        
        // Inject the JavaScript files into the web view.
        for jsFileString in javaScripts {
            webView.stringByEvaluatingJavaScriptFromString(jsFileString as! String)
        }
        
        // Inject the global app config into this web page.
        injectAppConfigInWebView(webView)
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        
        // Set the iOS status bar color.
        // We must not allow a previous screen to trigger this if a new screen has been loaded,
        // because otherwise we get a previous screen setting the status bar color for a later screen, which
        // results in the wrong status bar color.
        // window indicates whether the web view is currently visible.
        
        if (webView.window != nil) {
            webView.stringByEvaluatingJavaScriptFromString("Rhy.iOS.setStatusBarColor()")
        }
        
        for onLoadListener in self.onLoadListeners {
            onLoadListener(webView: webView)
        }
        if(self.form != nil) {
            self.renderFormData(self.form!)
        }
    }
    
    func injectAppConfigInWebView(webView: UIWebView) {
        // Inject the app's current configuration into the web view.
        // This is set by RSKConfig's setupAppConfig method in the AppDelegate. Note that this configuration is
        // mutable. It can be changed by calls to setAppConfigKey.
        if let appConfig = NSUserDefaults.standardUserDefaults().objectForKey(RHY_CONFIG_KEY) as? NSDictionary {
            let appConfigJSON = RHYUtils.JSONStringFromObject(dictionary: appConfig)!
            self.uiWebView.stringByEvaluatingJavaScriptFromString("Rhy.Config = JSON.parse('\(appConfigJSON)');");
        }
    }
    
    func addOnLoadListener(onLoadListener: OnLoadListener) {
        self.onLoadListeners.append(onLoadListener)
    }
    
    
    //    class Test {var xyz = 0}
    //    func initScreenFromViewControllerString(className: String) -> UIViewController {
    //        var target = NSBundle.mainBundle().objectForInfoDictionaryKey("RSKTargetName") as! String
    //        print("\(target)")
    //        print("\(_stdlib_getTypeName(ITAGeoNativeScreenViewController()))")
    //        print("\(_stdlib_getTypeName(Test()))")
    //
    //
    //
    //
    //        let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as String
    //        let appNameNoSpaces = appName.stringByReplacingOccurrencesOfString(" ", withString: "_", options: .LiteralSearch, range: nil)
    //        let mangledClassName = "_TtC\(countElements(appNameNoSpaces))\(appNameNoSpaces)\(countElements(className))\(className)"
    //        print(mangledClassName)
    //        var anyobjectype : AnyObject.Type = NSClassFromString(mangledClassName)
    //        var nsobjectype : NSObject.Type = anyobjectype as NSObject.Type
    //        var screen: UIViewController = nsobjectype() as UIViewController
    //        return screen
    //    }
    
    
}

