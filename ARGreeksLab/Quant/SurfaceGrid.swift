//
//  SurfaceGrid.swift
//  ARGreeksLab
//
//  Created by Rhea Shah on 12/30/25.
//

import Foundation

struct SurfaceGrid {
    let sAxis: [Double]   // underlying prices
    let tAxis: [Double]   // times to expiry
    let values: [[Double]] // e.g., price or delta grid

    static func generate(
        base: OptionParameters,
        sMinFactor: Double = 0.5,
        sMaxFactor: Double = 1.5,
        sSteps: Int = 40,
        tMin: Double = 0.01,
        tMax: Double = 1.0,
        tSteps: Int = 40,
        mode: SurfaceMode = .price
    ) -> SurfaceGrid {
        let S0 = base.spot
        let sMin = S0 * sMinFactor
        let sMax = S0 * sMaxFactor

        let ds = (sMax - sMin) / Double(sSteps - 1)
        let dt = (tMax - tMin) / Double(tSteps - 1)

        var sAxis = [Double]()
        var tAxis = [Double]()
        for i in 0..<sSteps {
            sAxis.append(sMin + Double(i) * ds)
        }
        for j in 0..<tSteps {
            tAxis.append(tMin + Double(j) * dt)
        }

        var values = Array(
            repeating: Array(repeating: 0.0, count: tSteps),
            count: sSteps
        )

        for i in 0..<sSteps {
            for j in 0..<tSteps {
                var p = base
                p.spot = sAxis[i]
                p.time = tAxis[j]

                let v: Double
                switch mode {
                case .price:
                    v = Quant.price(params: p)
                case .delta:
                    v = Quant.delta(params: p)
                }

                values[i][j] = v
            }
        }

        return SurfaceGrid(sAxis: sAxis, tAxis: tAxis, values: values)
    }
}

enum SurfaceMode {
    case price
    case delta
}

