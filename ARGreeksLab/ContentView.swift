//
//  ContentView.swift
//  ARGreeksLab
//
//  Created by Rhea Shah on 12/29/25.

// vision statement: lets users see option price surfaces and greeks as interactive 3D and AR objects
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    @State private var sampleText: String = "Generating grid..."

    var body: some View {
        ScrollView {
            Text(sampleText)
                .font(.system(.body, design: .monospaced))
                .padding()
        }
        .onAppear {
            runDebugGrid()
        }
    }

    private func runDebugGrid() {
        let base = OptionParameters(
            spot: 100,
            strike: 100,
            time: 0.5,
            volatility: 0.2,
            rate: 0.01,
            dividend: 0.0,
            type: .call
        )

        let grid = SurfaceGrid.generate(base: base, mode: .price)

        var lines: [String] = []
        lines.append("sAxis[0]=\(grid.sAxis.first ?? 0), sAxis[last]=\(grid.sAxis.last ?? 0)")
        lines.append("tAxis[0]=\(grid.tAxis.first ?? 0), tAxis[last]=\(grid.tAxis.last ?? 0)")
        lines.append("value[0][0]=\(grid.values[0][0])")
        lines.append("value[mid][mid]=\(grid.values[grid.values.count/2][grid.tAxis.count/2])")

        sampleText = lines.joined(separator: "\n")
    }
}

