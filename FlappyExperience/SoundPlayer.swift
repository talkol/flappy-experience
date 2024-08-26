//
//  FlappyExperience/SoundPlayer.swift
//  Created by Tal Kol
//
//  Play sound effects (WAV files).
//

import AVFoundation

enum Effect: String {
    case flap, score, thud, highscore
}

class SoundPlayer {
    var flap, score, thud, highscore: AVAudioPlayer
    
    init() {
        flap = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "flap", ofType:"wav")!))
        score = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "score", ofType:"wav")!))
        thud = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "thud", ofType:"wav")!))
        highscore = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "highscore", ofType:"wav")!))
    }
    
    func play(effect: Effect) {
        switch effect {
        case .flap:
            DispatchQueue.global().async {
                self.flap.volume = 1.5
                self.flap.currentTime = 0
                self.flap.play()
            }
            return
        case .score:
            DispatchQueue.global().async {
                self.score.volume = 2
                self.score.currentTime = 0
                self.score.play()
            }
            return
        case .thud:
            DispatchQueue.global().async {
                self.thud.volume = 1.5
                self.thud.currentTime = 0
                self.thud.play()
            }
            return
        case .highscore:
            DispatchQueue.global().async {
                self.highscore.volume = 1.1
                self.highscore.currentTime = 0
                self.highscore.play()
            }
            return
        }
    }
}
