//
//  ARViewContainer.swift
//  ARGreeksLab
//
//  Created by Rhea Shah on 12/30/25.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // configure ar session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]      // detect tables, floors
        config.environmentTexturing = .automatic   // nicer lighting
        arView.session.run(config)

        // add tap gesture recognizer
        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tap)

        context.coordinator.view = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // nothing for now
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        weak var view: ARView?

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = view else { return }

            let location = recognizer.location(in: view)

            // raycast to find a horizontal plane at this screen point
            let results = view.raycast(
                from: location,
                allowing: .estimatedPlane,
                alignment: .horizontal
            )

            guard let firstResult = results.first else { return }

            let position = SIMD3(
                x: firstResult.worldTransform.columns.3.x,
                y: firstResult.worldTransform.columns.3.y,
                z: firstResult.worldTransform.columns.3.z
            )

            placeSurface(at: position, in: view)
        }

        private func placeSurface(at position: SIMD3<Float>, in view: ARView) {
            // stub for now; we’ll fill it in next
        }
    }
}

