//
//  OptionModels.swift
//  ARGreeksLab
//
//  Created by Rhea Shah on 12/30/25.

// implements standard Black‑Scholes call/put pricing
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

struct Quant {

    static func normalCDF(_ x: Double) -> Double {
        // Approximation of standard normal CDF
        return 0.5 * erfc(-x / sqrt(2.0))
    }

    static func d1(params p: OptionParameters) -> Double {
        let S = p.spot
        let K = p.strike
        let T = p.time
        let sigma = p.volatility
        let r = p.rate
        let q = p.dividend

        return (log(S / K) + (r - q + 0.5 * sigma * sigma) * T) / (sigma * sqrt(T))
    }

    static func d2(params p: OptionParameters) -> Double {
        return d1(params: p) - p.volatility * sqrt(p.time)
    }

    static func price(params p: OptionParameters) -> Double {
        let S = p.spot
        let K = p.strike
        let T = p.time
        let r = p.rate
        let q = p.dividend

        let d1 = d1(params: p)
        let d2 = d2(params: p)

        switch p.type {
        case .call:
            return S * exp(-q * T) * normalCDF(d1) - K * exp(-r * T) * normalCDF(d2)
        case .put:
            return K * exp(-r * T) * normalCDF(-d2) - S * exp(-q * T) * normalCDF(-d1)
        }
    }
}

#if DEBUG
func testBlackScholes() {
    let params = OptionParameters(
        spot: 100,
        strike: 100,
        time: 0.5,
        volatility: 0.2,
        rate: 0.01,
        dividend: 0.0,
        type: .call
    )
    let p = Quant.price(params: params)
    print("Test call price:", p)
}
#endif

