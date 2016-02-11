//
//  RHYValueForKey.swift
//  EfiCash
//
//  Created by Ángel Balbuena on 1/15/16.
//  Copyright © 2016 Roshka. All rights reserved.
//

import UIKit

class RHYValueForKey: NSObject {
    
    class func getValueForKey(key: String) -> String? {
        if(key == "OS_VERSION") {
            let iOSVersion = UIDevice.currentDevice().systemVersion
            return iOSVersion
        }
        if(key == "DEVICE_MODEL") {
            let deviceName = UIDevice.currentDevice().model
            return deviceName
        }
        if(key == "UUID") {
            let deviceUUID = UIDevice.currentDevice().identifierForVendor!.UUIDString
            return deviceUUID
        }
        
        if((EFCSingleton.sharedInstance.session) != nil) {
            print(EFCSingleton.sharedInstance.session![key] as? String)
            return EFCSingleton.sharedInstance.session![key] as? String;
        }

        
        return nil
    }
    
    class func setValueForKey(key: String, value: AnyObject) -> Void {
        if((EFCSingleton.sharedInstance.session) != nil) {
            EFCSingleton.sharedInstance.session![key] = value;
        } else {
            EFCSingleton.sharedInstance.session = RSKDictionary()
            EFCSingleton.sharedInstance.session![key] = value;
        }
    }
}
