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
    var body: some View {
        ZStack(alignment: .top) {
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)

            Text("Move your phone to detect a surface, then tap to place the test surface.")
                .padding()
                .background(Color.black.opacity(0.5))
                .foregroundColor(.white)
                .font(.footnote)
        }
    }
}

