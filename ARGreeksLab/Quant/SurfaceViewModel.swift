// SurfaceViewModel.swift
// Part of ARGreeksLab
// Created by Rhea Shah on 12/30/2025

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

    @Published var selectedS: Double?
    @Published var selectedT: Double?
    @Published var selectedPrice: Double?
    @Published var selectedDelta: Double?
    @Published var selectedGamma: Double?

    @Published var comparisonEnabled: Bool = false
    private var baselineGrid: SurfaceGrid?

    // Reset trigger: toggled when user taps Reset
    @Published var resetSelectionAndAnchors: Bool = false

    // Simple debug message string for future use
    @Published var debugMessage: String?

    struct SurfaceData {
        let heights: [[Float]]
        let sAxis: [Double]
        let tAxis: [Double]
    }

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

    private func generateGrid() -> SurfaceGrid {
        let base = makeBaseParams()
        return SurfaceGrid.generate(
            base: base,
            sMinFactor: 0.5,
            sMaxFactor: 1.5,
            sSteps: sSteps,
            tMin: 0.01,
            tMax: timeMax,
            tSteps: tSteps,
            mode: mode
        )
    }

    func generateSurfaceData() -> SurfaceData {
        let grid = generateGrid()

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

        return SurfaceData(heights: heights, sAxis: grid.sAxis, tAxis: grid.tAxis)
    }

    func generateHeights() -> [[Float]] {
        generateSurfaceData().heights
    }

    func saveBaseline() {
        baselineGrid = generateGrid()
    }

    func generateDifferenceHeights() -> [[Float]]? {
        guard let baseline = baselineGrid else { return nil }
        let current = generateGrid()

        guard baseline.sAxis.count == current.sAxis.count,
              baseline.tAxis.count == current.tAxis.count else { return nil }

        var diff = Array(
            repeating: Array(repeating: Float(0), count: tSteps),
            count: sSteps
        )

        for i in 0..<sSteps {
            for j in 0..<tSteps {
                let d = current.values[i][j] - baseline.values[i][j]
                diff[i][j] = Float(d)
            }
        }

        let flat = diff.flatMap { $0 }
        if let maxAbs = flat.map({ abs($0) }).max(), maxAbs > 0 {
            let scale: Float = 0.1 / maxAbs
            for i in 0..<sSteps {
                for j in 0..<tSteps {
                    diff[i][j] *= scale
                }
            }
        }

        return diff
    }

    func updateSelection(i: Int, j: Int, sAxis: [Double], tAxis: [Double]) {
        guard i >= 0, i < sAxis.count,
              j >= 0, j < tAxis.count else { return }

        let base = makeBaseParams()
        var p = base
        p.spot = sAxis[i]
        p.time = tAxis[j]

        selectedS = sAxis[i]
        selectedT = tAxis[j]
        selectedPrice = Quant.price(params: p)
        selectedDelta = Quant.delta(params: p)
        selectedGamma = Quant.gamma(params: p)
    }

    func clearSelection() {
        selectedS = nil
        selectedT = nil
        selectedPrice = nil
        selectedDelta = nil
        selectedGamma = nil
    }
}



