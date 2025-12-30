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
    var time: Double      // T in years
    var volatility: Double // sigma
    var rate: Double      // r
    var dividend: Double  // q
    var type: OptionType
}

struct Quant {

    static func normalCDF(_ x: Double) -> Double {
        0.5 * erfc(-x / sqrt(2.0))
    }

    static func normalPDF(_ x: Double) -> Double {
        (1.0 / sqrt(2.0 * Double.pi)) * exp(-0.5 * x * x)
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
        d1(params: p) - p.volatility * sqrt(p.time)
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

    static func delta(params p: OptionParameters) -> Double {
        let d1 = d1(params: p)
        switch p.type {
        case .call:
            return exp(-p.dividend * p.time) * normalCDF(d1)
        case .put:
            return exp(-p.dividend * p.time) * (normalCDF(d1) - 1.0)
        }
    }

    static func gamma(params p: OptionParameters) -> Double {
        let d1 = d1(params: p)
        let S = p.spot
        let T = p.time
        let sigma = p.volatility
        return exp(-p.dividend * T) * normalPDF(d1) / (S * sigma * sqrt(T))
    }

    static func vega(params p: OptionParameters) -> Double {
        let d1 = d1(params: p)
        let S = p.spot
        let T = p.time
        return S * exp(-p.dividend * T) * normalPDF(d1) * sqrt(T)
    }

    static func theta(params p: OptionParameters) -> Double {
        let S = p.spot
        let K = p.strike
        let T = p.time
        let r = p.rate
        let q = p.dividend
        let sigma = p.volatility

        let d1 = d1(params: p)
        let d2 = d2(params: p)

        let term1 = -S * normalPDF(d1) * sigma * exp(-q * T) / (2.0 * sqrt(T))

        switch p.type {
        case .call:
            let term2 = q * S * exp(-q * T) * normalCDF(d1)
            let term3 = -r * K * exp(-r * T) * normalCDF(d2)
            return term1 + term2 + term3
        case .put:
            let term2 = -q * S * exp(-q * T) * normalCDF(-d1)
            let term3 = r * K * exp(-r * T) * normalCDF(-d2)
            return term1 + term2 + term3
        }
    }

    static func rho(params p: OptionParameters) -> Double {
        let K = p.strike
        let T = p.time
        let r = p.rate

        let d2 = d2(params: p)

        switch p.type {
        case .call:
            return K * T * exp(-r * T) * normalCDF(d2)
        case .put:
            return -K * T * exp(-r * T) * normalCDF(-d2)
        }
    }
}
