//
//  ARGreeksLabApp.swift
//  ARGreeksLab
//
//  Created by Rhea Shah on 12/29/25.
//

import SwiftUI

@main
struct ARGreeksLabApp: App {
    @StateObject private var surfaceVM = SurfaceViewModel()
    @State private var showAbout = false

    var body: some Scene {
        WindowGroup {
            ContentView(showAbout: $showAbout)
                .environmentObject(surfaceVM)
                .sheet(isPresented: $showAbout) {
                    AboutView()
                }
        }
    }
}

