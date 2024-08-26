//
//  ContentView.swift
//  FlappyExperience
//
//  Created by Tal Kol on 11/08/2024.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationStack {
            
            VStack() {
                
                Text("Flappy Experience")
                    .font(.system(size: 50, weight: .bold))
                
                Button("        Play        ") {
                    Task {
                        
                        await openImmersiveSpace(id: "ImmersiveSpace")
                        dismiss()
                        openWindow(id: "Game")
                        
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

#Preview(windowStyle: .automatic) {
    ContentView()
}
