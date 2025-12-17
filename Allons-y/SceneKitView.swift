import SwiftUI
import SceneKit

struct SceneKitView: UIViewRepresentable {
    @ObservedObject var viewModel: SceneViewModel

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = SCNScene()
        scnView.allowsCameraControl = true
        scnView.antialiasingMode = .multisampling4X
//        scnView.backgroundColor = UIColor.systemBackground
        scnView.backgroundColor = UIColor.black
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 8)
        scnView.scene?.rootNode.addChildNode(cameraNode)

        // Lights
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(5, 5, 10)
        scnView.scene?.rootNode.addChildNode(lightNode)

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor(white: 0.6, alpha: 1.0)
        scnView.scene?.rootNode.addChildNode(ambientLightNode)

        // Geometry
        let box = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0.1)
        let material = SCNMaterial()
        material.diffuse.contents = viewModel.uiColor
        box.materials = [material]

        // Replace the box creation with:
        // Try to load the TARDIS model; if it fails, fall back to the box
        let modelNode: SCNNode
        if let modelScene = SCNScene(named: "Models.scnassets/Simple TARDIS.usdc") {
            // Keep our existing scene (camera/lights) and add the model's contents
            let container = SCNNode()
            for child in modelScene.rootNode.childNodes {
                container.addChildNode(child.clone())
            }
            modelNode = container
        } else {
            // Fallback: use the existing box
            modelNode = SCNNode(geometry: box)
        }

        scnView.scene?.rootNode.addChildNode(modelNode)

        context.coordinator.modelNode = modelNode
        context.coordinator.startDisplayLink()

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let node = context.coordinator.modelNode else { return }

        // Apply transforms from the view model
        let rx = degreesToRadians(viewModel.rotationX)
        let ry = degreesToRadians(viewModel.rotationY)
        let rz = degreesToRadians(viewModel.rotationZ)
        node.eulerAngles = SCNVector3(rx, ry, rz)

        let s = Float(viewModel.scale)
        node.scale = SCNVector3(s, s, s)

        if let material = node.geometry?.firstMaterial {
            material.diffuse.contents = viewModel.uiColor
        }

        // Handle spinning
        context.coordinator.isSpinning = viewModel.isSpinning
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        weak var modelNode: SCNNode?
        var displayLink: CADisplayLink?
        var isSpinning: Bool = false
        var lastTimestamp: CFTimeInterval = 0

        func startDisplayLink() {
            stopDisplayLink()
            let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
            link.add(to: .main, forMode: .default)
            displayLink = link
        }

        func stopDisplayLink() {
            displayLink?.invalidate()
            displayLink = nil
            lastTimestamp = 0
        }

        @objc func tick(_ link: CADisplayLink) {
            guard isSpinning, let node = modelNode else { return }
            if lastTimestamp == 0 { lastTimestamp = link.timestamp }
            let dt = link.timestamp - lastTimestamp
            lastTimestamp = link.timestamp

            // Rotate ~1 radian per second around Y
            var angles = node.eulerAngles
            angles.y += Float(dt) * 1.0
            node.eulerAngles = angles
        }
    }

    // MARK: - Helpers
    private func degreesToRadians(_ deg: Double) -> Float {
        return Float(deg * .pi / 180.0)
    }
}
