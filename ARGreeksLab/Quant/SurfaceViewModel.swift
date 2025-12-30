//
//  SurfaceViewModel.swift
//  ARGreeksLab
//
//  Created by Rhea Shah on 12/30/25.
//
import Foundation
import Combine

final class SurfaceViewModel: ObservableObject {

    @Published var spot: Double = 100.0
    @Published var strike: Double = 100.0
    @Published var timeMax: Double = 1.0
    @Published var volatility: Double = 0.2
    @Published var rate: Double = 0.01
    @Published var dividend: Double = 0.0
    @Published var optionType: OptionType = .call
    @Published var mode: SurfaceMode = .price

    let sSteps: Int = 40
    let tSteps: Int = 40

    func makeBaseParams() -> OptionParameters {
        OptionParameters(
            spot: spot,
            strike: strike,
            time: 0.5,
            volatility: volatility,
            rate: rate,
            dividend: dividend,
            type: optionType
        )
    }

    func generateHeights() -> [[Float]] {
        let base = makeBaseParams()

        let grid = SurfaceGrid.generate(
            base: base,
            sMinFactor: 0.5,
            sMaxFactor: 1.5,
            sSteps: sSteps,
            tMin: 0.01,
            tMax: timeMax,
            tSteps: tSteps,
            mode: mode
        )

        var heights = Array(
            repeating: Array(repeating: Float(0), count: tSteps),
            count: sSteps
        )

        for i in 0..<sSteps {
            for j in 0..<tSteps {
                heights[i][j] = Float(grid.values[i][j])
            }
        }

        let flat = heights.flatMap { $0 }
        if let maxAbs = flat.map({ abs($0) }).max(), maxAbs > 0 {
            let scale: Float = 0.1 / maxAbs
            for i in 0..<sSteps {
                for j in 0..<tSteps {
                    heights[i][j] *= scale
                }
            }
        }

        return heights
    }
}


