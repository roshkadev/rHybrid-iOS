//
//  RHYhttp.swift
//  EfiCash
//
//  Created by Ángel Balbuena on 1/26/16.
//  Copyright © 2016 Roshka. All rights reserved.
//

import Foundation

class RHYhttp {
    class func httpRequest(url: String) -> String {
        let nsurl = NSURL(string: url)
        let request = NSURLRequest(URL: nsurl!)
        var responseData : String = ""

        return String(responseData)
    }
}