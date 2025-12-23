import SwiftUI
import Foundation
import UIKit
import Combine

/// View model that holds the state for the SceneKit 3D model.
/// SwiftUI controls bind to these properties, and the SceneKit view reads them
/// to update the node's transform and appearance.
final class SceneViewModel: ObservableObject {
    @Published var rotationX: Double = 0
    @Published var rotationY: Double = 0
    @Published var rotationZ: Double = 0
    @Published var scale: Double = 2.0
    @Published var color: Color = .orange
    @Published var isSpinning: Bool = false

    /// Versioned trigger to request a one-shot "Red Alert" action in the SceneKit view.
    @Published var redAlertVersion: Int = 0

    /// Call to request that the SceneKit view set the "Front-Back Windows" materials to red.
    func requestRedAlert() {
        // Use wrapping add to avoid overflow traps while still changing the value
        redAlertVersion &+= 1
    }

    init() {}

    /// UIColor representation of the current SwiftUI Color for SceneKit materials.
    var uiColor: UIColor { UIColor(color) }
}
