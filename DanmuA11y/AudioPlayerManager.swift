//
//  AudioPlayerManager.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/6/29.
//

import AVFoundation

class AudioPlayerManager: ObservableObject {
    @Published var audioPlayers: [AVAudioPlayer] = []
    let audioFiles = ["audio1", "audio2", "audio3"]
    
    init() {
        setupAudioPlayers()
    }
    
    private func setupAudioPlayers() {
        for audioFile in audioFiles {
            if let audioURL = Bundle.main.url(forResource: audioFile, withExtension: "mp3") {
                do {
                    let audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                    audioPlayer.numberOfLoops = -1 // Loop indefinitely
                    audioPlayers.append(audioPlayer)
                } catch {
                    print("Failed to initialize audio player for \(audioFile): \(error)")
                }
            }
        }
    }
    
    func startAudio() {
        for audioPlayer in audioPlayers {
            audioPlayer.currentTime = 0
            audioPlayer.play()
        }
    }

    func stopAudio() {
        for audioPlayer in audioPlayers {
            audioPlayer.stop()
        }
    }

    func updateAudioVolumes(index: Int, audioVolumes1: [Float], audioVolumes2: [Float], audioVolumes3: [Float]) {
        guard !audioPlayers.isEmpty else { return }
        let limitedIndex = min(max(index, 0), audioVolumes1.count - 1)
        audioPlayers[0].volume = audioVolumes1[limitedIndex]
        audioPlayers[1].volume = audioVolumes2[limitedIndex]
        audioPlayers[2].volume = audioVolumes3[limitedIndex]
    }
}
