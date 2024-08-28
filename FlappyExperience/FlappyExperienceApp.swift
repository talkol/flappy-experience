//
//  FlappyExperience/FlappyExperienceApp.swift
//  Created by Tal Kol
//
//  Main entry point for the SwiftUI app, defines all windows and spaces.
//

import SwiftUI

@main
struct FlappyExperienceApp: App {
    @State private var model = GameModel()
    @State private var gestureModel = HandGestureModel()
    @State private var positionModel = HeadsetPositionModel()
    
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(model)
                .environment(positionModel)
                .environment(gestureModel)
                .frame(width: 800, height: 650)
        }
        .windowResizability(.contentSize)
        
        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
                .environment(model)
                .environment(positionModel)
                .environment(gestureModel)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
        
        ImmersiveSpace(id: "MixedSpace") {
            ImmersiveView()
                .environment(model)
                .environment(positionModel)
                .environment(gestureModel)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
