//ARViewContainer
//Part of ARGreeksLab

// Created by Rhea Shah on 12/30/2025

import SwiftUI
import RealityKit
import ARKit
import Combine

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

        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.5
        arView.addGestureRecognizer(longPress)

        context.coordinator.view = arView
        context.coordinator.connect(to: surfaceVM)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.connect(to: surfaceVM)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        weak var view: ARView?
        private var surfaceVM: SurfaceViewModel?
        private var cancellables: Set<AnyCancellable> = []

        private var currentModel: ModelEntity?
        private var diffModel: ModelEntity?
        private var lastHeights: [[Float]] = []
        private var lastSAxis: [Double] = []
        private var lastTAxis: [Double] = []

        func connect(to vm: SurfaceViewModel) {
            surfaceVM = vm
            cancellables.removeAll()

            vm.$resetSelectionAndAnchors
                .sink { [weak self] _ in
                    self?.resetScene()
                    vm.clearSelection()
                }
                .store(in: &cancellables)
        }

        private func resetScene() {
            guard let view = view else { return }
            view.scene.anchors.removeAll()
            currentModel = nil
            diffModel = nil
            lastHeights = []
            lastSAxis = []
            lastTAxis = []
        }

        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard recognizer.state == .began,
                  let view = view,
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

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = view,
                  let vm = surfaceVM,
                  let model = currentModel else { return }

            let location = recognizer.location(in: view)
            let hits = view.hitTest(location)

            if let result = hits.first(where: { $0.entity == model }) {
                let local = result.position
                inspectHit(localPosition: local, using: vm)
            }
        }

        private func placeSurface(
            at position: SIMD3<Float>,
            in view: ARView,
            using vm: SurfaceViewModel
        ) {
            resetScene()

            let data = vm.generateSurfaceData()
            lastHeights = data.heights
            lastSAxis = data.sAxis
            lastTAxis = data.tAxis

            let width: Float = 0.6
            let depth: Float = 0.6

            let mainMesh = makeMeshFromHeightMap(
                heights: lastHeights,
                width: width,
                depth: depth
            )

            var mainMaterial = SimpleMaterial()
            mainMaterial.color = .init(tint: .blue, texture: nil)

            let mainEntity = ModelEntity(mesh: mainMesh, materials: [mainMaterial])

            var pos = position
            pos.y += 0.001
            mainEntity.position = pos

            let anchor = AnchorEntity(world: pos)
            anchor.addChild(mainEntity)

            if vm.comparisonEnabled, let diffHeights = vm.generateDifferenceHeights() {
                let diffMesh = makeMeshFromHeightMap(
                    heights: diffHeights,
                    width: width,
                    depth: depth
                )

                var diffMaterial = SimpleMaterial()
                diffMaterial.color = .init(tint: .red, texture: nil)

                let diffEntity = ModelEntity(mesh: diffMesh, materials: [diffMaterial])
                diffEntity.position = SIMD3<Float>(pos.x + width + 0.1, pos.y, pos.z)
                anchor.addChild(diffEntity)
                diffModel = diffEntity
            }

            view.scene.addAnchor(anchor)
            currentModel = mainEntity
        }

        private func inspectHit(
            localPosition: SIMD3<Float>,
            using vm: SurfaceViewModel
        ) {
            guard !lastHeights.isEmpty,
                  !lastSAxis.isEmpty,
                  !lastTAxis.isEmpty else { return }

            let rows = lastHeights.count
            let cols = lastHeights.first?.count ?? 0
            guard rows > 1, cols > 1 else { return }

            let width: Float = 0.6
            let depth: Float = 0.6
            let dx = width / Float(cols - 1)
            let dz = depth / Float(rows - 1)
            let xOffset = -width / 2
            let zOffset = -depth / 2

            let jFloat = (localPosition.x - xOffset) / dx
            let iFloat = (localPosition.z - zOffset) / dz

            let i = max(0, min(rows - 1, Int(round(iFloat))))
            let j = max(0, min(cols - 1, Int(round(jFloat))))

            vm.updateSelection(i: i, j: j, sAxis: lastSAxis, tAxis: lastTAxis)
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

