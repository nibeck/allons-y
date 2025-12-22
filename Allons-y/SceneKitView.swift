import SwiftUI
import SceneKit

struct SceneKitView: UIViewRepresentable {
    @ObservedObject var viewModel: SceneViewModel

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = SCNScene()
        scnView.allowsCameraControl = true
        scnView.antialiasingMode = .multisampling4X
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

        // Display the node tree of the model
        dumpNodes(modelNode)
        
        // After context.coordinator.modelNode = modelNode
        indexParts(in: modelNode, coordinator: context.coordinator)
        
        // Debug: Dump the indexed parts to ensure they were found
        dumpIndex(coordinator: context.coordinator)
        
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

        // Handle Red Alert trigger
        if context.coordinator.lastHandledRedAlertVersion != viewModel.redAlertVersion {
            context.coordinator.lastHandledRedAlertVersion = viewModel.redAlertVersion

            // Define the pulse action (Red -> Black -> Red)
            let duration: TimeInterval = 0.5
            
            let toBlack = SCNAction.customAction(duration: duration) { node, elapsedTime in
                let percentage = elapsedTime / CGFloat(duration)
                // Red (1,0,0) to Black (0,0,0)
                let val = 1.0 - percentage
                self.setMaterials(of: node, to: UIColor(red: val, green: 0, blue: 0, alpha: 1))
            }
            
            let toRed = SCNAction.customAction(duration: duration) { node, elapsedTime in
                let percentage = elapsedTime / CGFloat(duration)
                // Black (0,0,0) to Red (1,0,0)
                let val = percentage
                self.setMaterials(of: node, to: UIColor(red: val, green: 0, blue: 0, alpha: 1))
            }
            
            let pulse = SCNAction.sequence([toBlack, toRed])
            let threePulses = SCNAction.repeat(pulse, count: 3)
            
            // Start Red, Pulse 3 times, End Red
            let setRed = SCNAction.run { node in
                self.setMaterials(of: node, to: .red)
            }
            
            let sequence = SCNAction.sequence([setRed, threePulses, setRed])
            
            // Apply directly to parts stored in the coordinator
            for nodes in context.coordinator.parts.values {
                for node in nodes {
                    node.removeAllActions()
                    node.runAction(sequence)
                }
            }
        }
    }

    func dumpNodes(_ node: SCNNode, indent: String = "") {
        let geomName = node.geometry?.name ?? "no geometry"
        print("\(indent)- \(node.name ?? "<unnamed>") [\(geomName)]")
        for child in node.childNodes {
            dumpNodes(child, indent: indent + "  ")
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Node utilities
    private func findNode(named exactName: String, under root: SCNNode) -> SCNNode? {
        if root.name == exactName { return root }
        for child in root.childNodes {
            if let found = findNode(named: exactName, under: child) { return found }
        }
        return nil
    }

    private func findNode(containingName partial: String, under root: SCNNode) -> SCNNode? {
        if let name = root.name, name.localizedCaseInsensitiveContains(partial) { return root }
        for child in root.childNodes {
            if let found = findNode(containingName: partial, under: child) { return found }
        }
        return nil
    }

    private func setMaterials(of node: SCNNode, to color: UIColor) {
        // If this node has geometry, recolor all its materials
        if let materials = node.geometry?.materials, !materials.isEmpty {
            for m in materials { m.diffuse.contents = color }
        }
        // Recurse into children to ensure the whole subtree is recolored
        for child in node.childNodes {
            setMaterials(of: child, to: color)
        }
    }

    private func indexParts(in root: SCNNode, coordinator: Coordinator) {
        // Direct assignment using exact names
        coordinator.parts[.frontWindows] = findNodes(named: "Front_Windows", under: root)
        coordinator.parts[.leftWindows] = findNodes(named: "Left_Windows", under: root)
        coordinator.parts[.rearWindows] = findNodes(named: "Rear_Windows", under: root)
        coordinator.parts[.rightWindows] = findNodes(named: "Right_Windows", under: root)
        coordinator.parts[.topLightGlass] = findNodes(named: "Top_Light_Glass", under: root)

        // Validate that all parts were found
        var missingParts = false
        for key in PartKey.allCases {
            if let parts = coordinator.parts[key], !parts.isEmpty {
                continue
            }
            missingParts = true
        }
        
        if missingParts {
            print("Bad Model")
            dumpIndex(coordinator: coordinator)
            fatalError("Bad Model")
        }
    }

    private func dumpIndex(coordinator: Coordinator) {
        print("--- 3D Part Index Dump ---")
        if coordinator.parts.isEmpty {
            print("Index is empty!")
        } else {
            for (key, nodes) in coordinator.parts {
                print("Key: \(key) - Found \(nodes.count) node(s)")
                for node in nodes {
                    print("  -> \(node.name ?? "<unnamed>")")
                }
            }
        }
        print("--------------------------")
    }
    
    // MARK: - Helpers
    private func degreesToRadians(_ deg: Double) -> Float {
        return Float(deg * .pi / 180.0)
    }

    private func findNodes(named exactName: String, under root: SCNNode) -> [SCNNode] {
        var results: [SCNNode] = []
        if root.name == exactName { results.append(root) }
        for child in root.childNodes {
            results.append(contentsOf: findNodes(named: exactName, under: child))
        }
        return results
    }

    private func findNodes(containingName partial: String, under root: SCNNode) -> [SCNNode] {
        var results: [SCNNode] = []
        if let name = root.name, name.localizedCaseInsensitiveContains(partial) {
            results.append(root)
        }
        for child in root.childNodes {
            results.append(contentsOf: findNodes(containingName: partial, under: child))
        }
        return results
    }
    
    final class Coordinator: NSObject {
        weak var modelNode: SCNNode?
        var displayLink: CADisplayLink?
        var isSpinning: Bool = false
        var lastTimestamp: CFTimeInterval = 0
        var lastHandledRedAlertVersion: Int = 0

        // Cached parts
        var parts: [PartKey: [SCNNode]] = [:]
        
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
    
    enum PartKey: CaseIterable, Hashable {
        case frontWindows
        case rearWindows
        case leftWindows
        case rightWindows
        case topLightGlass
    }
}
