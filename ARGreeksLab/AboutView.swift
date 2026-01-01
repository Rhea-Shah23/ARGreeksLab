//
//  AboutView.swift
//  ARGreeksLab
//
//  Created by Rhea Shah on 1/1/26.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("AR Greeks Lab")
                        .font(.title2)
                        .bold()

                    Text("This app visualizes option prices and Greeks as 3D surfaces in augmented reality. It uses the Black‑Scholes model to compute price, delta, and gamma over grids of spot price and time to expiry.")
                        .font(.body)

                    Text("Quant engine")
                        .font(.headline)
                    Text("• European option pricing with the Black‑Scholes formula.\n• Analytic Greeks: delta, gamma and more.\n• Surfaces generated over a range of spot prices and maturities.")
                        .font(.body)

                    Text("ML component (planned)")
                        .font(.headline)
                    Text("• A small neural network can be trained on synthetic Black‑Scholes data to approximate prices or Greeks.\n• The app can compare analytic vs learned surfaces to show approximation error and speed/accuracy tradeoffs.")
                        .font(.body)

                    Text("How to use")
                        .font(.headline)
                    Text("1. Move your phone to detect a flat surface.\n2. Long‑press to place a surface.\n3. Use sliders to change spot, volatility, and time horizon.\n4. Tap the surface to inspect a point (S, T, price, delta, gamma).\n5. Save a baseline, change parameters, and enable Compare to see a difference surface.")
                        .font(.body)

                    Text("Debugging tips")
                        .font(.headline)
                    Text("• If you do not see a surface, move the device slowly over a textured table or floor and try a long‑press again.\n• If the surface looks flat, try increasing volatility or time.\n• If taps do nothing, make sure you are tapping directly on the blue surface, not empty space.\n• Use the Reset button if the scene gets cluttered or tracking feels off, then place a new surface.")
                        .font(.body)
                }
                .padding()
            }
            .navigationBarTitle("About", displayMode: .inline)
        }
    }
}

