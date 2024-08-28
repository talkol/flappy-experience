//
//  FlappyExperience/TitleView.swift
//  Created by Tal Kol
//
//  The main title menu, shown when the app starts outside immersive space.
//

import SwiftUI

struct TitleView: View {
    @Environment(GameModel.self) private var model
    @Environment(HandGestureModel.self) private var gestureModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openURL) var openURL
    
    var body: some View {
        @Bindable var model = model
        NavigationStack {
            VStack() {
                Text("Flappy Experience")
                    .font(.system(size: 50, weight: .bold))
                
                Button("                " + "Play" + "                ") {
                    Task {
                        if !(await gestureModel.requestAuth(model: model)) {
                            return
                        }
                        if model.immersiveModeFull {
                            await openImmersiveSpace(id: "ImmersiveSpace")
                        } else {
                            await openImmersiveSpace(id: "MixedSpace")
                        }
                    }
                }
                .font(.title)
                .tint(Color.blue)
                .padding(.top, 100)
                .padding(.bottom, 20)
                
                Toggle("Full Immersion", isOn: $model.immersiveModeFull)
                    .frame(maxWidth: 200)
                    .padding(.bottom, 80)
                                
                Text("This experience is free and open source on Github.")
                Text("You can improve it or publish your own version.").padding(.bottom)
                
                HStack {
                    Button("Github") {
                        openURL(URL(string: "https://github.com/talkol/flappy-experience")!)
                    }
                    NavigationLink("Credits", destination: {
                        CreditsView()
                    })
                }
            }
        }
    }
}

#Preview {
    TitleView()
        .environment(GameModel())
        .environment(HandGestureModel())
        .frame(width: 800, height: 650)
        .glassBackgroundEffect()
}
