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
    @EnvironmentObject var surfaceVM: SurfaceViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        arView.session.run(config)

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tap)

        context.coordinator.view = arView
        context.coordinator.surfaceVM = surfaceVM

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.surfaceVM = surfaceVM
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        weak var view: ARView?
        var surfaceVM: SurfaceViewModel?

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = view,
                  let vm = surfaceVM else { return }

            let location = recognizer.location(in: view)
            let results = view.raycast(
                from: location,
                allowing: .existingPlaneInfinite,
                alignment: .horizontal
            )

            guard let firstResult = results.first else { return }

            let position = SIMD3<Float>(
                x: firstResult.worldTransform.columns.3.x,
                y: firstResult.worldTransform.columns.3.y,
                z: firstResult.worldTransform.columns.3.z
            )

            placeSurface(at: position, in: view, using: vm)
        }

        private func placeSurface(
            at position: SIMD3<Float>,
            in view: ARView,
            using vm: SurfaceViewModel
        ) {
            view.scene.anchors.removeAll()

            let heights = vm.generateHeights()

            let width: Float = 0.3
            let depth: Float = 0.3

            let mesh = makeMeshFromHeightMap(
                heights: heights,
                width: width,
                depth: depth
            )

            var material = SimpleMaterial()
            material.color = .init(tint: .blue, texture: nil)

            let modelEntity = ModelEntity(mesh: mesh, materials: [material])

            var pos = position
            pos.y += 0.001
            modelEntity.position = pos

            let anchor = AnchorEntity(world: pos)
            anchor.addChild(modelEntity)
            view.scene.addAnchor(anchor)
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
