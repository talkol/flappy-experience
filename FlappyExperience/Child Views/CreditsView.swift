//
//  FlappyExperience/CreditsView.swift
//  Created by Tal Kol
//
//  Credits dialog to attribute all open source contributions this project relies on.
//

import SwiftUI

struct CreditsView: View {
    @ObservedObject var model: TextFileReaderModel = TextFileReaderModel(filename: "Credits")
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 100) {
                Text(model.data).frame(maxWidth: .infinity)
            }
            .padding()
            .navigationBarTitle("Credits")
        }
    }
}

#Preview {
    CreditsView()
        .frame(width: 800, height: 650)
        .glassBackgroundEffect()
}
