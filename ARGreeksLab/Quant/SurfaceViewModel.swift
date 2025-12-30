//
//  SurfaceViewModel.swift
//  ARGreeksLab
//
//  Created by Rhea Shah on 12/30/25.
//

import Foundation
import Combine

enum SurfaceMode {
    case price
    case delta
}

final class SurfaceViewModel: ObservableObject {

    // Exposed parameters for UI
    @Published var spot: Double = 100.0
    @Published var strike: Double = 100.0
    @Published var timeMax: Double = 1.0      // years for top of surface
    @Published var volatility: Double = 0.2   // sigma
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
            time: 0.5,             // will be overwritten in grid
            volatility: volatility,
            rate: rate,
            dividend: dividend,
            type: optionType
        )
    }

    /// Generate a height map [[Float]] for the current settings
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

        // Convert Double grid.values to [[Float]]
        var heights = Array(
            repeating: Array(repeating: Float(0), count: tSteps),
            count: sSteps
        )

        for i in 0..<sSteps {
            for j in 0..<tSteps {
                heights[i][j] = Float(grid.values[i][j])
            }
        }

        // Normalize heights a bit so AR scale looks reasonable
        let flat = heights.flatMap { $0 }
        if let maxAbs = flat.map({ abs($0) }).max(), maxAbs > 0 {
            let scale: Float = 0.1 / maxAbs   // scale tallest peak to ~0.1m
            for i in 0..<sSteps {
                for j in 0..<tSteps {
                    heights[i][j] *= scale
                }
            }
        }

        return heights
    }
}

