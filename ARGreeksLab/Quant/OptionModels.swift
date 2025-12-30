//
//  OptionModels.swift
//  ARGreeksLab
//
//  Created by Rhea Shah on 12/30/25.
//

import Foundation

enum OptionType {
    case call
    case put
}

struct OptionParameters {
    var spot: Double      // S
    var strike: Double    // K
    var time: Double      // T (years)
    var volatility: Double // sigma
    var rate: Double      // r
    var dividend: Double  // q
    var type: OptionType
}

