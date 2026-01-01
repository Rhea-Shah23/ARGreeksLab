//  ContentView.swift
//  ARGreeksLab
//  Created by Rhea Shah on 12/29/25.

// vision statement: lets users see option price surfaces and greeks as interactive 3D and AR objects


import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    @EnvironmentObject var surfaceVM: SurfaceViewModel
    @Binding var showAbout: Bool

    var body: some View {
        ZStack {
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 8) {
                instructionBar
                selectionInfo
                Spacer()
                controlPanel
            }
        }
    }

    private var instructionBar: some View {
        HStack {
            Text("Long‑press to place a surface. Tap the surface to inspect a point.")
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            Button("About") {
                showAbout = true
            }
            .font(.caption2)
        }
        .padding(8)
        .background(Color.black.opacity(0.6))
        .foregroundColor(.white)
    }

    private var selectionInfo: some View {
        Group {
            if let s = surfaceVM.selectedS,
               let t = surfaceVM.selectedT,
               let price = surfaceVM.selectedPrice,
               let delta = surfaceVM.selectedDelta,
               let gamma = surfaceVM.selectedGamma {

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "S = %.2f, T = %.2f", s, t))
                    Text(String(format: "Price = %.4f", price))
                    Text(String(format: "Delta = %.4f", delta))
                    Text(String(format: "Gamma = %.4f", gamma))
                }
                .font(.caption)
                .padding(8)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal, 8)
            }
        }
    }

    private var controlPanel: some View {
        VStack(spacing: 8) {
            Text(
                "Spot: \(Int(surfaceVM.spot))  " +
                "σ: \(String(format: "%.2f", surfaceVM.volatility))  " +
                "T: \(String(format: "%.2f", surfaceVM.timeMax))"
            )
            .font(.caption)
            .padding(.top, 4)

            Slider(value: $surfaceVM.spot, in: 50...150, step: 1)
            Slider(value: $surfaceVM.volatility, in: 0.05...0.8, step: 0.01)
            Slider(value: $surfaceVM.timeMax, in: 0.1...2.0, step: 0.05)

            Picker("Mode", selection: $surfaceVM.mode) {
                Text("Price").tag(SurfaceMode.price)
                Text("Delta").tag(SurfaceMode.delta)
                Text("Gamma").tag(SurfaceMode.gamma)
            }
            .pickerStyle(.segmented)

            HStack {
                Button("Save Baseline") {
                    surfaceVM.saveBaseline()
                }
                .font(.caption2)
                .padding(6)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(6)

                Toggle("Compare", isOn: $surfaceVM.comparisonEnabled)
                    .toggleStyle(SwitchToggleStyle())
                    .font(.caption2)

                Spacer()

                Button("Reset") {
                    surfaceVM.resetSelectionAndAnchors.toggle()
                }
                .font(.caption2)
                .padding(6)
                .background(Color.red.opacity(0.2))
                .cornerRadius(6)
            }

            Spacer().frame(height: 8)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
