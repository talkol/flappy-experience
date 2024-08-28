//
//  FlappyExperience/HeadsetPositionModel.swift
//  Created by Tal Kol
//
//  Use ARKit to track the player's headset position in the scene.
//

import ARKit
import QuartzCore

@Observable
class HeadsetPositionModel {
    @ObservationIgnored var session = ARKitSession()
    @ObservationIgnored var worldTracking = WorldTrackingProvider()
    
    @MainActor
    func start() async {
        session = ARKitSession()
        worldTracking = WorldTrackingProvider()
        do {
            if WorldTrackingProvider.isSupported {
                print("ARKitSession for world tracking starting.")
                try await session.run([worldTracking])
            }
        } catch {
            print("ARKitSession error:", error)
        }
    }
    
    @MainActor
    func computeHeadsetTransform() -> simd_float4x4 {
        guard let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())
        else { return .init() }
        return deviceAnchor.originFromAnchorTransform
    }
}
