//
//  FlappyExperience/HandGestureModel.swift
//  Created by Tal Kol
//
//  Use ARKit to track player's hands and compute joint locations for the flap gesture.
//

import ARKit

struct FlapHandGesture {
    var chirality: HandAnchor.Chirality
    var wristHeight: Float
    var wristDirection: Direction
}

enum Direction: String, CaseIterable, Identifiable {
    case idle, up, down
    var id: Self { self }
}

@Observable
class HandGestureModel {
    @ObservationIgnored var session = ARKitSession()
    @ObservationIgnored var handTracking = HandTrackingProvider()
    
    let minDiffForDirection: Float = 0.005 // Small movements below this threshold will not trigger an update.
    @ObservationIgnored var lastWristHeights = [HandAnchor.Chirality.left: Float(0), HandAnchor.Chirality.right: Float(0)]
    
    @MainActor
    func requestAuth(model: GameModel) async -> Bool {
#if targetEnvironment(simulator)
        // Simulator does not support auth requests.
        return true
#else
        let request = await session.requestAuthorization(for: [.handTracking])
        for (type, status) in request {
            if type == .handTracking && status != .allowed {
                model.handTrackingAuthorizationDenied = true
                return false
            }
            if type == .handTracking && status == .allowed {
                model.handTrackingAuthorizationDenied = false
                return true
            }
        }
        return false
#endif
    }
    
    @MainActor
    func start() async {
        session = ARKitSession()
        handTracking = HandTrackingProvider()
        do {
            if HandTrackingProvider.isSupported {
                print("ARKitSession for hand tracking starting.")
                try await session.run([handTracking])
            }
        } catch {
            print("ARKitSession error:", error)
        }
    }
    
    @MainActor
    func monitorSessionEvents(model: GameModel) async {
        for await event in session.events {
            switch event {
            case .authorizationChanged(let type, let status):
                if type == .handTracking && status != .allowed {
                    // Ask the user to grant hand tracking authorization again in Settings.
                    model.handTrackingAuthorizationDenied = true
                }
                if type == .handTracking && status == .allowed {
                    model.handTrackingAuthorizationDenied = false
                }
            default:
                print("Session event \(event)")
            }
        }
    }
    
    @MainActor
    func computeFlapHandGesture(anchor: HandAnchor) -> FlapHandGesture? {
        guard anchor.isTracked,
              let wrist = anchor.handSkeleton?.joint(.wrist),
              wrist.isTracked
        else { return nil }
        
        // Get the position of all joints in world coordinates.
        let originFromWristTransform = matrix_multiply(
            anchor.originFromAnchorTransform, wrist.anchorFromJointTransform
        ).columns.3.xyz
        let wristHeight = originFromWristTransform.y
        
        // Compute the direction of movement related to the last height.
        let lastWristHeight = lastWristHeights[anchor.chirality]!
        if wristHeight - lastWristHeight > minDiffForDirection {
            lastWristHeights[anchor.chirality] = wristHeight
            return FlapHandGesture(chirality: anchor.chirality, wristHeight: wristHeight, wristDirection: .up)
        } else if lastWristHeight - wristHeight > minDiffForDirection {
            lastWristHeights[anchor.chirality] = wristHeight
            return FlapHandGesture(chirality: anchor.chirality, wristHeight: wristHeight, wristDirection: .down)
        } else {
            return nil
        }
    }
}

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}
