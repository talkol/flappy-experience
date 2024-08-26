//
//  FlappyExperience/GameReadyView.swift
//  Created by Tal Kol
//
//  Are you ready menu, shown before a new round starts inside immersive space.
//

import SwiftUI

struct GameReadyView: View {
    @Environment(GameModel.self) private var model
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.dismissWindow) var dismissWindow
    @State private var bouncing = false
    
    var body: some View {
        @Bindable var model = model
        VStack() {
            Text("Ready?")
                .font(.system(size: 50, weight: .bold))
            
            Text("Flap your arms downwards to start")
                .frame(maxHeight: 50, alignment: bouncing ? .bottom : .top)
                .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bouncing)
                .onAppear {
                    self.bouncing.toggle()
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            
            Form {
                List {
                    LabeledContent("Score", value: String(model.score))
                    LabeledContent("Best", value: String(model.getBest()))
                    
                    Picker(selection: $model.difficulty) {
                        Text("Very Easy").tag(Difficulty.veryEasy)
                        Text("Easy").tag(Difficulty.easy)
                        Text("Medium").tag(Difficulty.medium)
                        Text("Hard").tag(Difficulty.hard)
                    } label: {
                        Text("Difficulty")
                    }
                    
                    Toggle("Music", isOn: $model.music)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: 340, maxHeight: 280)
            
            HStack {
                Button("        " + "Flap" + "        ") {
                    start(model: model, dismissWindow: dismissWindow)
                }
                Button("        " + "Quit" + "        ") {
                    Task {
                        await dismissImmersiveSpace()
                    }
                }
            }
        }.onChange(of: model.difficulty) {
            difficultyChanged(model: model)
        }
    }
}

#Preview {
    GameReadyView()
        .environment(GameModel())
        .frame(width: 800, height: 650)
        .glassBackgroundEffect()
}
