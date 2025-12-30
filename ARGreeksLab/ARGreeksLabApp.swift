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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(surfaceVM)
        }
    }
}
