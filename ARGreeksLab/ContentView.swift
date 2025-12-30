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
    @EnvironmentObject var surfaceVM: SurfaceViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)

            controlPanel
        }
    }

    private var controlPanel: some View {
        VStack(spacing: 8) {
            Text("Spot: \(Int(surfaceVM.spot))  σ: \(String(format: "%.2f", surfaceVM.volatility))  T: \(String(format: "%.2f", surfaceVM.timeMax))")
                .font(.caption)
                .padding(.top, 4)

            // slider: spot
            Slider(value: $surfaceVM.spot, in: 50...150, step: 1)

            //slider: volatility
            Slider(value: $surfaceVM.volatility, in: 0.05...0.8, step: 0.01)

            // slider: time max
            Slider(value: $surfaceVM.timeMax, in: 0.1...2.0, step: 0.05)

            Picker("Mode", selection: $surfaceVM.mode) {
                Text("Price").tag(SurfaceMode.price)
                Text("Delta").tag(SurfaceMode.delta)
            }
            .pickerStyle(.segmented)

            Spacer().frame(height: 8)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

