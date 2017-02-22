//
//  GlucoseMeasurement+Extension
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 1/12/17.
//  Copyright © 2017 eHealth Innovation. All rights reserved.
//

import Foundation
import CCGlucose

extension GlucoseMeasurement {
    private struct AssociatedKeys {
        static var existsOnFHIR: Bool = false
        static var fhirID: String = ""
    }
    
    var existsOnFHIR: Bool! {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.existsOnFHIR) as? Bool
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.existsOnFHIR, newValue as Bool!, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    var fhirID: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.fhirID) as? String
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.fhirID, newValue as String?, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}
