//
//  FlappyExperience/ImmersiveView.swift
//  Created by Tal Kol
//
//  The immersive space where the game takes place (load and plays the RealityKit scene).
//

import SwiftUI
import RealityKit
import RealityKitContent
import GameController

struct ImmersiveView: View {
    @Environment(GameModel.self) private var model
    @Environment(HandGestureModel.self) private var gestureModel
    @Environment(HeadsetPositionModel.self) private var positionModel
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    var body: some View {
        RealityView { content in
            // Add the initial RealityKit scene content.
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
                // Update relevant entities in the game model.
                model.sceneContent = immersiveContentEntity
                model.pipeBotEntities.removeAll()   // Reset model in case has leftovers.
                model.pipeTopEntities.removeAll()   // Reset model in case has leftovers.
                model.pipeBotHeights.removeAll()    // Reset model in case has leftovers.
                for pipeIndex in 0...(model.numPipes - 1) {
                    let pipeBot = immersiveContentEntity.findEntity(named: "Pipe_\(pipeIndex)_bot")
                    let pipeTop = immersiveContentEntity.findEntity(named: "Pipe_\(pipeIndex)_top")
                    if pipeBot != nil && pipeTop != nil {
                        model.pipeBotEntities.append(pipeBot!)
                        model.pipeTopEntities.append(pipeTop!)
                        model.pipeBotHeights.append(0)
                    }
                }
                
#if targetEnvironment(simulator)
                // Allow control through the keyboard in the simulator only (since no hand gestures).
                Task.detached {
                    for await _ in NotificationCenter.default.notifications(named: .GCKeyboardDidConnect) {
                        Task { @MainActor in
                            GCKeyboard.coalesced?.keyboardInput?.keyChangedHandler = { keyboard, key, keyCode, pressed in
                                Task {
                                    // Space button pressed.
                                    if (keyCode.rawValue == 44 && pressed) {
                                        flap(model: model, dismissWindow: dismissWindow)
                                    }
                                }
                            }
                        }
                    }
                }
#endif
                
                // Add a light source for the immersive content scene.
                guard let resource = try? await EnvironmentResource(named: "ImageBasedLight") else { return }
                let iblComponent = ImageBasedLightComponent(source: .single(resource), intensityExponent: 0.25)
                immersiveContentEntity.components.set(iblComponent)
                immersiveContentEntity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: immersiveContentEntity))
                
                // Add a skybox for the immersive content scene.
                var skyboxMaterial = UnlitMaterial()
                skyboxMaterial.color = .init(tint:UIColor(red: 0.439, green: 0.769, blue: 0.808, alpha: 1))
                let skybox = Entity()
                skybox.components.set(ModelComponent(
                    mesh: .generateSphere(radius: 0.1),
                    materials: [skyboxMaterial]
                ))
                skybox.scale *= .init(x: -10000, y: 10000, z: 10000)
                immersiveContentEntity.addChild(skybox)
                
                // Run the gameloop on every frame.
                let _ = content.subscribe(to: SceneEvents.Update.self) { event in
                    gameloop(model: model, deltaTime: Float(event.deltaTime), openWindow: openWindow)
                }
                
                // Reset the player's position so we can start the game.
                respawn(model: model, positionModel: nil)
            }
        }
        .onAppear {
            model.immersiveMode = true
        }
        .onDisappear {
            model.immersiveMode = false
        }
        .task {
            await positionModel.start()
            try! await Task.sleep(for: .seconds(0.5)) // Let the session actually start.
            checkHeadsetPosition(model: model, positionModel: positionModel)
        }
        .task {
            await gestureModel.start()
        }
        .task {
            await gestureModel.monitorSessionEvents(model: model)
        }
        .task {
            // Go over hand tracking update events.
            for await update in gestureModel.handTracking.anchorUpdates {
                if update.event == .updated {
                    guard let flapGesture = gestureModel.computeFlapHandGesture(anchor: update.anchor) else { continue }
                    checkFlapGesture(model: model, gesture: flapGesture, dismissWindow: dismissWindow)
                }
            }
        }
    }
}
