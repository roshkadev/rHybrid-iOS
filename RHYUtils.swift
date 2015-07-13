//
//  RSKUtils.swift
//  rsk-hybrid
//
//  Created by Paul Von Schrottky on 11/25/14.
//  Copyright (c) 2014 Roshka. All rights reserved.
//

import UIKit

class RHYUtils: NSObject {
    
    class func platformCode() -> String {
        var size: size_t = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](count: Int(size), repeatedValue: 0)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String.fromCString(machine)!
    }
    
    class func rfc822DateAsEscapedString() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss z"
        let formattedDateString = dateFormatter.stringFromDate(NSDate())
        let escapedDateString = formattedDateString.stringByReplacingOccurrencesOfString("+", withString: "%2b", options: .allZeros, range: nil)
        return escapedDateString
    }
    
    class func JSONStringFromObject(dictionary object: NSDictionary) -> NSString? {
        var error: NSError?
        var jsonData =  NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions.allZeros, error: &error)
        var jsonString: NSString
        if (jsonData == nil) {
            println("Could not convert JSON string to NSDictionary.")
            return nil
        } else {
            jsonString = NSString(data: jsonData!, encoding: NSUTF8StringEncoding)!
        }
        return jsonString
    }
    
    class func objectForJSONString(JSONString string: NSString) -> AnyObject {
        var data = string.dataUsingEncoding(NSUTF8StringEncoding)
        var error: NSError?
        return NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.allZeros, error: &error)!
    }
    
    
    class func dictionaryFromQueryParams(queryParams: NSString) -> NSDictionary {
        var params = NSMutableDictionary();
        let pairs = queryParams.componentsSeparatedByString("&")
        for pair in pairs {
            let elements = pair.componentsSeparatedByString("=");
            var key = elements[0] as! NSString;
            var value = elements[1] as! NSString;
            key = key.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            value = value.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            params.setObject(value, forKey: key)
        }
        return params
    }
    
    class func URLSchemeForThisApplication() -> NSString {
        let URLTypes = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleURLTypes") as! NSArray
        let URLType = URLTypes[0] as! NSDictionary
        let URLSchemes = URLType["CFBundleURLSchemes"] as! NSArray
        let URLScheme = URLSchemes[0] as! NSString
        return URLScheme
    }
    
    class func statusBar(inView view:UIView) {
        var statusBar = UIView()
        statusBar.backgroundColor = UIColor().RSKDodgerBlue
        statusBar.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(statusBar)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            "H:|[statusBar]|",
            options: NSLayoutFormatOptions(0),
            metrics: nil,
            views: ["statusBar": statusBar]))
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            "V:|[statusBar(64)]",
            options: NSLayoutFormatOptions(0),
            metrics: nil,
            views: ["statusBar": statusBar]))
    }
}

extension UIColor {
    var RSKWhite:       UIColor { return UIColor(red: 255/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1.0) }
    var RSKDodgerBlue:  UIColor { return UIColor(red:  30/255.0, green: 144/255.0, blue: 255/255.0, alpha: 1.0) }
    var RSKYellow:      UIColor { return UIColor(red: 240/255.0, green: 230/255.0, blue: 140/255.0, alpha: 1.0) }
    var RSKCrimson:     UIColor { return UIColor(red: 220/255.0, green: 20/255.0,  blue:  60/255.0, alpha: 1.0) }
    var RSKNavajoWhite: UIColor { return UIColor(red: 255/255.0, green: 222/255.0, blue: 173/255.0, alpha: 1.0) }
}

extension UIFont {
    var RSKStandard:    UIFont { return UIFont(name: "Hanken-Light", size: 20.0)! }
}

extension NSDictionary {
    func JSONString_rsk() -> NSString? {
        var error: NSError?
        if let JSONData = NSJSONSerialization.dataWithJSONObject(self, options: nil, error: &error) {
            return NSString(data: JSONData, encoding: NSUTF8StringEncoding)!
        }
        return nil
    }
}
