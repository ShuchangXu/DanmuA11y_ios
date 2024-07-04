//
//  AudioEngineManager.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/7/2.
//

import AVFoundation

class AudioEngineManager: ObservableObject {
    private var audioEngine = AVAudioEngine()
    private var sampler = AVAudioUnitSampler()
    
    init() {
        audioEngine.attach(sampler)
        audioEngine.connect(sampler, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine couldn't start: \(error)")
        }
    }
    
    func playSound(pitch: Double, duration: Double) {
        let noteNumber = UInt8(60 + 2 * pitch) // Middle C is 60, adjust as needed
        sampler.startNote(noteNumber, withVelocity: 127, onChannel: 0)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + duration) {
            self.sampler.stopNote(noteNumber, onChannel: 0)
        }
    }
}
