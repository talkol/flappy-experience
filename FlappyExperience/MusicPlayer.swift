//
//  FlappyExperience/MusicPlayer.swift
//  Created by Tal Kol
//
//  Play background music (MP3 tracks).
//

import AVFoundation

let numTracks = 9
let numSurprises = 4

class MusicPlayer: NSObject, AVAudioPlayerDelegate {
    var avPlayer: AVAudioPlayer?
    
    func play() {
        let trackNum = Int.random(in: 1..<(numTracks+1))
        let track = "track" + String(trackNum)
        play(fileName: track)
    }
    
    func playSurprise() {
        let trackNum = Int.random(in: 1..<(numSurprises+1))
        let track = "surprise" + String(trackNum)
        play(fileName: track)
    }
    
    private func play(fileName: String) {
        guard let path = Bundle.main.path(forResource: fileName, ofType:"mp3") else {
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            avPlayer = try AVAudioPlayer(contentsOf: url)
            avPlayer?.delegate = self
            DispatchQueue.global().async {
                self.avPlayer?.currentTime = 0
                self.avPlayer?.play()
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func stop() {
        avPlayer?.stop()
        avPlayer = nil
    }
    
    func onEndTrack() {
        stop()
        play()
    }
    
    @objc func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag && avPlayer != nil  {
            onEndTrack()
        }
    }
}
