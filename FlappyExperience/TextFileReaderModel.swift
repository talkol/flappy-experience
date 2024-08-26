//
//  FlappyExperience/TextFileReaderModel.swift
//  Created by NSGodMode in https://stackoverflow.com/questions/61581482/how-do-i-load-the-contents-of-a-text-file-and-display-it-in-a-swiftui-text-view
//
//  Load contents of a markdown (MD) file in the bundle so it can be displayed in a view.
//

import SwiftUI

class TextFileReaderModel: ObservableObject {
    @Published public var data: LocalizedStringKey = ""
    
    init(filename: String) { self.load(file: filename) }
    
    func load(file: String) {
        if let filepath = Bundle.main.path(forResource: file, ofType: "md") {
            do {
                let contents = try String(contentsOfFile: filepath)
                DispatchQueue.main.async {
                    self.data = LocalizedStringKey(contents)
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } else {
            print("File not found")
        }
    }
}
