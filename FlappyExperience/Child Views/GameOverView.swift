//
//  FlappyExperience/GameOverView.swift
//  Created by Tal Kol
//
//  Game over menu, shown after the player dies inside immersive space.
//

import SwiftUI

struct GameOverView: View {
    @Environment(GameModel.self) private var model
    @Environment(HeadsetPositionModel.self) private var positionModel
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    var body: some View {
        VStack() {
            if model.score <= model.getBest() {
                Text("Game Over")
                    .font(.system(size: 50, weight: .bold))
            } else {
                Text("High Score")
                    .font(.system(size: 50, weight: .bold))
            }
            Form {
                List {
                    LabeledContent("Score", value: String(model.score))
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: 340, maxHeight: 80)
            .padding(60)
            
            HStack {
                Button("        " + "Try Again" + "        ") {
                    respawn(model: model, positionModel: positionModel)
                }
                Button("        " + "Quit" + "        ") {
                    Task {
                        await dismissImmersiveSpace()
                    }
                }
            }
        }
    }
}

#Preview {
    GameOverView()
        .environment(GameModel())
        .frame(width: 800, height: 650)
        .glassBackgroundEffect()
}
