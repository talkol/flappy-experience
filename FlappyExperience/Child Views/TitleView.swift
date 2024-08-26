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
        NavigationStack {
            VStack() {
                Text("Flappy Experience")
                    .font(.system(size: 50, weight: .bold))
                
                Button("        " + "Play" + "        ") {
                    Task {
                        if !(await gestureModel.requestAuth(model: model)) {
                            return
                        }
                        await openImmersiveSpace(id: "ImmersiveSpace")
                    }
                }
                .font(.title)
                .tint(Color.blue)
                .padding(120)
                
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
