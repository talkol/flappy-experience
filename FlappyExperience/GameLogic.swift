//
//  FlappyExperience/GameLogic.swift
//  Created by Tal Kol
//
//  All game logic for various game events reading from the game data model and modifying it as needed.
//

import SwiftUI
import RealityKit

// Respawn the player in the beginning of the course, before starting a new round.
@MainActor
func respawn(model: GameModel) {
    model.gameOver = false
    model.nextPipeIndex = model.firstPipeIndex
    model.passedNextPipeFirstEdge = false
}

// Start a new round and let player control the character.
@MainActor
func start(model: GameModel, dismissWindow: DismissWindowAction) {
    for pipeIndex in 0...(model.numPipes - 1) {
        // Don't move the pipe in front of the player, it looks bad.
        if pipeIndex != model.firstPipeIndex {
            randomizePipeHeight(model: model, pipeIndex: pipeIndex)
        }
    }
    if model.score > model.getBest() {
        model.setBest(best: model.score)
    }
    model.score = 0
    dismissWindow(id: "main")
}

// Handle a flap action by the player.
@MainActor
func flap(model: GameModel, dismissWindow: DismissWindowAction) {
    if model.gamePlaying {
        model.verticalVelocity = model.getFlapVerticalVelocity()
        model.soundPlayer.play(effect: .flap)
    } else if model.immersiveMode {
        if !model.gameOver {
            // Start the game if not started yet.
            start(model: model, dismissWindow: dismissWindow)
        } else {
            respawn(model: model)
        }
    }
}

// We do efficient collision detection in only two points for each pipe, the two pipe edges (front and back).
@MainActor
func arrivedAtPipeEdge(model: GameModel, openWindow: OpenWindowAction) {
    // Check collision with the bottom pipe.
    if model.playerHeight + model.playerHeadAboveFloor < model.pipeBotHeights[model.nextPipeIndex % model.numPipes] {
        die(model: model, openWindow: openWindow)
    }
    // Check collision with the top pipe.
    if model.playerHeight + model.playerHeadAboveFloor > model.pipeBotHeights[model.nextPipeIndex % model.numPipes] + model.getPipeGap() {
        die(model: model, openWindow: openWindow)
    }
    
    // Fix the state machine to make sure we get called on both edges for each pipe.
    if !model.passedNextPipeFirstEdge {
        // Player arrived at the first edge of the next pipe (entering the pipe circumference).
        model.passedNextPipeFirstEdge = true
    } else {
        // Player arrived at the second edge of the next pipe (leaving the pipe circumference).
        model.passedNextPipeFirstEdge = false
        // Randomize the height of the next next next pipe to keep things fresh all the time.
        randomizePipeHeight(model: model, pipeIndex: (model.nextPipeIndex + 3) % model.numPipes)
        model.nextPipeIndex += 1
        // Increase score if player is still alive.
        if model.gamePlaying {
            score(model: model)
        }
    }
}

// Player has scored one point by passing a pipe successfully.
@MainActor
func score(model: GameModel) {
    model.score += 1
    model.soundPlayer.play(effect: .score)
    if model.score % model.numPipeScoredBeforeSurprise == 0 {
        model.musicPlayer.playSurprise()
    }
}

// Player has died either by hitting the ground or hitting a pipe.
@MainActor
func die(model: GameModel, openWindow: OpenWindowAction) {
    if model.gamePlaying {
        model.gamePlaying = false
        model.gameOver = true
        model.verticalVelocity = 0
        model.soundPlayer.play(effect: .thud)
        openWindow(id: "main")
        if model.score > model.getBest() {
            model.soundPlayer.play(effect: .highscore)
        }
    }
}

// The primary game loop logic, this runs on every frame (at 90 FPS) so must be very efficient.
@MainActor
func gameloop(model: GameModel, deltaTime: Float, openWindow: OpenWindowAction) {
    // Player is playing the game and flapping, no dialog is shown.
    if model.gamePlaying {
        model.verticalVelocity += model.getGravity() * deltaTime
        model.playerHeight += deltaTime * model.verticalVelocity
        model.worldAngle += deltaTime * model.forwardAngularVelocity
        updateWorldTransform(model: model)
        
        // Check if player hits the ground.
        if model.playerHeight + model.playerHeadAboveFloor < model.heightGroundDeath {
            die(model: model, openWindow: openWindow)
        }
        
        // Check if player arrives at a pipe.
        let nextPipeWorldAngle = (0.5 + Float(model.nextPipeIndex - model.firstPipeIndex)) * 2 * Float.pi / Float(model.numPipes)
        let pipeRadiusWorldAngle = model.pipeRadius / model.worldRadius
        if !model.passedNextPipeFirstEdge {
            if model.worldAngle > nextPipeWorldAngle - pipeRadiusWorldAngle {
                arrivedAtPipeEdge(model: model, openWindow: openWindow)
            }
        } else {
            if model.worldAngle > nextPipeWorldAngle + pipeRadiusWorldAngle {
                arrivedAtPipeEdge(model: model, openWindow: openWindow)
            }
        }
        
        return
    }
    
    // Player has respawned but didn't start playing yet, Ready? dialog is shown.
    if !model.gamePlaying && !model.gameOver {
        let jiggle = Float(sin(Date.timeIntervalSinceReferenceDate))
        model.worldAngle = 0.01 * jiggle
        model.playerHeight = model.playerInitialHeight + 0.1 * jiggle
        updateWorldTransform(model: model)
        
        return
    }
}

@MainActor
func difficultyChanged(model: GameModel) {
    for pipeIndex in 0...(model.numPipes - 1) {
        randomizePipeHeight(model: model, pipeIndex: pipeIndex, onInit: true)
    }
}

// Move the world towards the player instead of moving the camera in the scene, since VisionOS RealityKit likes stationary cameras.
@MainActor
func updateWorldTransform(model: GameModel) {
    model.sceneContent?.transform.rotation = .init(angle: model.worldAngle, axis: [1,0,0])
    model.sceneContent?.transform.translation = [0,-1 * (model.worldRadius + model.playerHeight) ,0]
}

// To keep the level interesting, randomize pipe heights when player can't see them.
@MainActor
func randomizePipeHeight(model: GameModel, pipeIndex: Int, onInit: Bool = false) {
    var randomFraction = Float.random(in: 0..<1)
    if onInit && pipeIndex == model.firstPipeIndex {
        // First pipe has half the distance so half the random height as well.
        randomFraction /= 2
    }
    let pipeBotHeight = model.worldRadius + model.pipeRandomHeightMin + model.pipeRandomHeightRange * randomFraction
    let pipeTopHeight = pipeBotHeight + model.getPipeGap()
    let angle = Float(pipeIndex) * 2 * Float.pi / Float(model.numPipes)
    model.pipeBotHeights[pipeIndex] = pipeBotHeight - model.worldRadius
    model.pipeBotEntities[pipeIndex].transform.translation = [0, pipeBotHeight * sin(angle), pipeBotHeight * cos(angle)]
    model.pipeTopEntities[pipeIndex].transform.translation = [0, pipeTopHeight * sin(angle), pipeTopHeight * cos(angle)]
}

// Used for debugging pipe indexes, not found in production code.
@MainActor
func deletePipe(model: GameModel, pipeIndex: Int) {
    model.pipeTopEntities[pipeIndex].removeFromParent()
}

// Check if we should trigger a flap based on hand gesture joint information, runs frequently so must be efficient.
@MainActor
func checkFlapGesture(model: GameModel, gesture: FlapHandGesture, dismissWindow: DismissWindowAction) {
    if gesture.wristDirection == .up {
        // Start the gesture.
        model.flapGestureStartTime[gesture.chirality] = Date.timeIntervalSinceReferenceDate
        model.flapGestureStartHeight[gesture.chirality] = gesture.wristHeight
    } else {
        let gestureStartTime = model.flapGestureStartTime[gesture.chirality]!
        let gestureStartHeight = model.flapGestureStartHeight[gesture.chirality]!
        if gestureStartTime != 0 {
            // There a gesture currently active, check if it's completed.
            let currTime = Date.timeIntervalSinceReferenceDate
            if currTime - gestureStartTime > model.flapGestureMaxTime {
                // The gesture is taking too long, kill the active gesture.
                model.flapGestureStartTime[gesture.chirality] = 0
                model.flapGestureStartHeight[gesture.chirality] = 0
            } else if gestureStartHeight - gesture.wristHeight > model.flapGestureMinHeight {
                // Completed the gesture successfully.
                if currTime - model.flapLastCompleted > model.flapGestureMinTimeBetween {
                    // Trigger a flap but not too frequently.
                    flap(model: model, dismissWindow: dismissWindow)
                    model.flapLastCompleted = currTime
                }
                model.flapGestureStartTime[gesture.chirality] = 0
                model.flapGestureStartHeight[gesture.chirality] = 0
            }
        }
    }
}

// Calculate the position of the player's headset above the floor in real life.
@MainActor
func checkHeadsetPosition(model: GameModel, positionModel: HeadsetPositionModel) {
    let headsetPosition = positionModel.computeHeadsetTransform().columns.3.xyz
    print("Player headset height is ", headsetPosition.y)
    model.playerHeadAboveFloor = headsetPosition.y
}

// Used in edge cases where game cannot longer run, such as authrization for hand tracking suddenly removed.
@MainActor
func interruptGame(model: GameModel, openWindow: OpenWindowAction, dismissImmersiveSpace: DismissImmersiveSpaceAction) async {
    if model.gamePlaying {
        model.gamePlaying = false
        openWindow(id: "main")
    }
    if model.immersiveMode {
        await dismissImmersiveSpace()
    }
}
