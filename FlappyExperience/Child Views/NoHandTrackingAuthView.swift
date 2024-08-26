//
//  FlappyExperience/NoHandTrackingAuthView.swift
//  Created by Tal Kol
//
//  Error dialog explaining that hand tracking authorization denied.
//

import SwiftUI

struct NoHandTrackingAuthView: View {
    @Environment(GameModel.self) private var model
    @Environment(HandGestureModel.self) private var gestureModel
    
    var body: some View {
        VStack() {
            Text("Tracking Required")
                .font(.system(size: 50, weight: .bold))
            
            Text("Hand tracking authorization denied.").padding(.top, 40)
            Text("Try authorizing again or fix in Settings.").padding(.bottom, 70)
            
            HStack {
                Button("Try Again") {
                    Task {
                        if !(await gestureModel.requestAuth(model: model)) {
                            return
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NoHandTrackingAuthView()
        .environment(GameModel())
        .environment(HandGestureModel())
        .frame(width: 800, height: 650)
        .glassBackgroundEffect()
}
