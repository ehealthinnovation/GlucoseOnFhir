//
//  GlucoseHelper.swift
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 7/14/17.
//  Copyright © 2017 eHealth Innovation. All rights reserved.
//

import Foundation

extension Float {
    func truncateMeasurement() -> Float {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = NumberFormatter.RoundingMode.down
        let truncatedValue = formatter.string(from: NSNumber(value: self))
        
        return Float(truncatedValue!)!
    }
}
