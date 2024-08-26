//
//  FlappyExperience/ContentView.swift
//  Created by Tal Kol
//
//  All user interface panels shown to the player as menus during the game.
//

import SwiftUI

struct ContentView: View {
    @Environment(GameModel.self) private var model
    
    var body: some View {
        Group {
            if model.handTrackingAuthorizationDenied {
                // Hand tracking denied dialog (outside or inside immersive space).
                NoHandTrackingAuthView()
            }
            else if !model.immersiveMode {
                // Main title menu (outside immersive space).
                TitleView()
            }
            else if !model.gameOver {
                // Are you ready menu (inside immersive space).
                GameReadyView()
            } else {
                // Game over menu (inside immersive space).
                GameOverView()
            }
        }
        .onAppear {
            model.gamePlaying = false
        }
        .onDisappear {
            model.gamePlaying = true
        }
    }
}
