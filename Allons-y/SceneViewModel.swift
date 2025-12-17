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
    @Published var scale: Double = 1.0
    @Published var color: Color = .teal
    @Published var isSpinning: Bool = false

    init() {}

    /// UIColor representation of the current SwiftUI Color for SceneKit materials.
    var uiColor: UIColor { UIColor(color) }
}

