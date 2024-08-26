//
//  FlappyExperience/GameModel.swift
//  Created by Tal Kol
//
//  Shared game state information representing the data model of the game which all views rely on.
//

import SwiftUI
import RealityKit
import ARKit

enum Difficulty: String, CaseIterable, Identifiable {
    case veryEasy, easy, medium, hard
    var id: Self { self }
}

@Observable
class GameModel {
    // Constants /////////////////////////////////////////////////////////////////////
    
    // Tweak these to modify the game difficulty settings.
    let gravity = [                             // Gravity strengh.
        Difficulty.veryEasy: Float(-5),
        Difficulty.easy: Float(-7),
        Difficulty.medium: Float(-9.81),
        Difficulty.hard: Float(-9.81),
    ]
    let pipeGap = [                             // Gap between the top and bottom halves of a pipe.
        Difficulty.veryEasy: Float(6),
        Difficulty.easy: Float(4.5),
        Difficulty.medium: Float(3),
        Difficulty.hard: Float(2.5),
    ]
    let flapVerticalVelocity = [                // How powerful a flap is.
        Difficulty.veryEasy: Float(4),
        Difficulty.easy: Float(6),
        Difficulty.medium: Float(8),
        Difficulty.hard: Float(9),
    ]
    
    // Tweak these to modify gameplay.
    let forwardAngularVelocity: Float = 0.2     // How fast is the player moving over the planet.
    let heightGroundDeath: Float = 0.5          // The height above ground which below the player dies by hitting the ground.
    let playerInitialHeight: Float = 3          // The initial height the player starts at when a new round starts.
    let numPipeScoredBeforeSurprise = 15        // If the player gets a multiple of this score they get a surprise.
    
    // Tweak these to control flap gesture params.
    let flapGestureMaxTime: TimeInterval = 1            // Max time player has to complete gesture.
    let flapGestureMinHeight: Float = 0.10              // Min distance player has to move hands vertically.
    let flapGestureMinTimeBetween: TimeInterval = 0.4   // How frequently can the player flap (time between two).
    
    // Tweak these if 3D models for the game are modified.
    let worldRadius: Float = 20                 // The radius of the world planet.
    let pipeRadius: Float = 1.5/2               // The radius of the pipe opening.
    let numPipes = 6                            // The number of pipes in the world, spread evenly from angle zero.
    let firstPipeIndex = 2                      // When respawning, the first pipe we see is entity "Pipe_2_top" + "Pipe_2_bot".
    let pipeRandomHeightMin: Float = 1          // The minimum height a pipe can be when its height is randomized.
    let pipeRandomHeightRange: Float = 12       // The range of heights a pipe can be when its height is randomized.
    let pipeRandomFirstPipe: Float = 0.33       // The random value for the first pipe isn't so random.
    
    // Classes used to play music and sound effects.
    let musicPlayer: MusicPlayer = .init()      // Plays background music.
    let soundPlayer: SoundPlayer = .init()      // Plays sound effects.
    
    
    // Non-Publishing State //////////////////////////////////////////////////////////
    
    // Physics related state.
    @ObservationIgnored var worldAngle: Float = 0                   // Angle in radians that the world planet is rotated.
    @ObservationIgnored var pipeBotHeights: [Float] = []            // The height of bottom part of each pipe on the world planet.
    @ObservationIgnored var playerHeight: Float = 0                 // The current height of the player over the world planet.
    @ObservationIgnored var verticalVelocity: Float = 0             // The vertical velocity of the player.
    @ObservationIgnored var nextPipeIndex = 0                       // Which pipe index is the next one the player will encounter.
    @ObservationIgnored var passedNextPipeFirstEdge = false         // Did the player pass the front edge of the next pipe yet.
    
    // Headset position related state.
    @ObservationIgnored var playerHeadAboveFloor: Float = 1.6       // How high is the Vision Pro headset above the floor in real life.
    
    // Flap gesture related state.
    @ObservationIgnored var flapGestureStartTime = [                // When did the flap gesture start (per hand).
        HandAnchor.Chirality.left: TimeInterval(0),
        HandAnchor.Chirality.right: TimeInterval(0)
    ]
    @ObservationIgnored var flapGestureStartHeight = [              // When the flap gesture started, how high was the hand (per hand).
        HandAnchor.Chirality.left: Float(0),
        HandAnchor.Chirality.right: Float(0)
    ]
    @ObservationIgnored var flapLastCompleted: TimeInterval = 0     // When was the last flap completed (either hand).
    
    // References to RealityKit entities we need to modify in runtime.
    @ObservationIgnored var sceneContent: Entity?                   // Outside environment of the world - planet terrain, clouds, pipes, buildings.
    @ObservationIgnored var pipeBotEntities: [Entity] = []          // Bottom parts of all pipes on the world planet.
    @ObservationIgnored var pipeTopEntities: [Entity] = []          // Top parts of all pipes on the world planet.
    
    
    // Publishing State //////////////////////////////////////////////////////////////
    
    // Is the app in immersive mode or in the main title menu.
    var immersiveMode = false {
        didSet {
            if immersiveMode {
                if music {
                    musicPlayer.play()
                }
            } else {
                musicPlayer.stop()
            }
        }
    }
    
    // While in immersive mode, is the game actualy playing or is a menu dialog is shown.
    var gamePlaying = false
    
    // While in immersive mode, did the player just die and game over dialog is shown.
    var gameOver = false
    
    // Is there a problem with user authorization for hand tracking.
    var handTrackingAuthorizationDenied = false
    
    // Game setting - should background music be playing.
    var music = true {
        didSet {
            storedMusic = music
            if immersiveMode {
                if music {
                    musicPlayer.play()
                } else {
                    musicPlayer.stop()
                }
            }
        }
    }
    
    // Game setting - the difficulty level of the game.
    var difficulty: Difficulty = .medium {
        didSet {
            storedDifficulty = difficulty
        }
    }
    
    // The score of the player in the last game round (how many pipes passed).
    var score: Int = 0
    
    // The all-time high score in very easy difficulty.
    var veryEasyBest: Int = 0 {
        didSet {
            storedVeryEasyBest = veryEasyBest
        }
    }
    
    // The all-time high score in easy difficulty.
    var easyBest: Int = 0 {
        didSet {
            storedEasyBest = easyBest
        }
    }
    
    // The all-time high score in medium difficulty.
    var mediumBest: Int = 0 {
        didSet {
            storedMediumBest = mediumBest
        }
    }
    
    // The all-time high score in hard difficulty.
    var hardBest: Int = 0 {
        didSet {
            storedHardBest = hardBest
        }
    }
    
    init() {
        music = storedMusic
        difficulty = storedDifficulty
        veryEasyBest = storedVeryEasyBest
        easyBest = storedEasyBest
        mediumBest = storedMediumBest
        hardBest = storedHardBest
    }
    
    
    // Persistent Storage ////////////////////////////////////////////////////////////
    
    @ObservationIgnored @AppStorage("music") var storedMusic: Bool = true
    @ObservationIgnored @AppStorage("difficulty") var storedDifficulty: Difficulty = .medium
    @ObservationIgnored @AppStorage("veryEasyBest") var storedVeryEasyBest: Int = 0
    @ObservationIgnored @AppStorage("easyBest") var storedEasyBest: Int = 0
    @ObservationIgnored @AppStorage("mediumBest") var storedMediumBest: Int = 0
    @ObservationIgnored @AppStorage("hardBest") var storedHardBest: Int = 0
    
    
    // Getters and Setters ///////////////////////////////////////////////////////////
    
    func getGravity() -> Float {
        return gravity[difficulty]!
    }
    
    func getPipeGap() -> Float {
        return pipeGap[difficulty]!
    }
    
    func getFlapVerticalVelocity() -> Float {
        return flapVerticalVelocity[difficulty]!
    }
    
    func getBest() -> Int {
        switch difficulty {
        case .veryEasy:
            return veryEasyBest
        case .easy:
            return easyBest
        case .medium:
            return mediumBest
        case .hard:
            return hardBest
        }
    }
    
    func setBest(best: Int) {
        switch difficulty {
        case .veryEasy:
            veryEasyBest = best
        case .easy:
            easyBest = best
            return
        case .medium:
            mediumBest = best
            return
        case .hard:
            hardBest = best
            return
        }
    }
}
