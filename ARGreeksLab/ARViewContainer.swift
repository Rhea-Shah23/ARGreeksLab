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
                allowing: .existingPlaneGeometry,
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
            // Remove previous anchors (only one surface at a time for now)
            view.scene.anchors.removeAll()

            // Generate a simple height map
            let gridSize = 30
            let width: Float = 0.3     // meters in AR world
            let depth: Float = 0.3

            let heights = generateHeightMap(size: gridSize)

            let mesh = makeMeshFromHeightMap(
                heights: heights,
                width: width,
                depth: depth
            )

            var material = SimpleMaterial()
            material.color = .init(tint: .blue, texture: nil)

            let modelEntity = ModelEntity(mesh: mesh, materials: [material])
            modelEntity.position = position

            let anchor = AnchorEntity(world: position)
            anchor.addChild(modelEntity)
            view.scene.addAnchor(anchor)
        }

        private func generateHeightMap(size: Int) -> [[Float]] {
            var data = Array(
                repeating: Array(repeating: Float(0), count: size),
                count: size
            )

            for i in 0..<size {
                for j in 0..<size {
                    let x = Float(i) / Float(size - 1) * Float.pi * 2
                    let y = Float(j) / Float(size - 1) * Float.pi * 2
                    data[i][j] = 0.05 * sin(x) * cos(y) // small wave
                }
            }
            return data
        }

        private func makeMeshFromHeightMap(
            heights: [[Float]],
            width: Float,
            depth: Float
        ) -> MeshResource {
            let rows = heights.count
            let cols = heights.first?.count ?? 0

            var positions: [SIMD3<Float>] = []
            var indices: [UInt32] = []

            let dx = width / Float(cols - 1)
            let dz = depth / Float(rows - 1)

            // center around (0,0)
            let xOffset = -width / 2
            let zOffset = -depth / 2

            for i in 0..<rows {
                for j in 0..<cols {
                    let x = xOffset + Float(j) * dx
                    let z = zOffset + Float(i) * dz
                    let y = heights[i][j]
                    positions.append(SIMD3<Float>(x, y, z))
                }
            }

            // two triangles per grid cell
            for i in 0..<(rows - 1) {
                for j in 0..<(cols - 1) {
                    let topLeft = UInt32(i * cols + j)
                    let topRight = UInt32(i * cols + j + 1)
                    let bottomLeft = UInt32((i + 1) * cols + j)
                    let bottomRight = UInt32((i + 1) * cols + j + 1)

                    indices.append(contentsOf: [
                        topLeft, bottomLeft, topRight,
                        topRight, bottomLeft, bottomRight
                    ])
                }
            }

            var meshDescriptor = MeshDescriptor()
            meshDescriptor.positions = .init(positions)
            meshDescriptor.primitives = .triangles(indices)

            return try! MeshResource.generate(from: [meshDescriptor])
        }

    }
}

