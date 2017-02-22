//
//  DispatchQueue+Extension.swift
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 1/26/17.
//  Copyright © 2017 eHealth Innovation. All rights reserved.
//

import Foundation

extension DispatchQueue {
    private static var _tokenTracker = [String]()
    
    public class func once(executeToken: String, block: (Void) -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if _tokenTracker.contains(executeToken) {
            return
        }
        
        _tokenTracker.append(executeToken)
        block()
    }
}
