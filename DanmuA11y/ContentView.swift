//
//  ContentView.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/6/29.
//

import SwiftUI
import AVKit
import AVFoundation
import CoreHaptics

struct ContentView: View {
//    @StateObject private var audioPlayerManager = AudioPlayerManager()
    @StateObject private var audioEngineManager = AudioEngineManager()
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var hapticEngine: CHHapticEngine?
    @State private var player: AVPlayer
    @State private var mySliderValue: Double = 0.0
    @State private var videoDuration: Double = 0.0
    
    @State private var isDraggingSlider = false
    @State private var wasPlayingBeforeDrag = false
    @State private var stableCount: Double = 0.0
    @State private var isSpeaking = false
    @State private var lastSliderValue: Double = 0.0
    
    @State private var sceneTimes: [Double] = []
    @State private var sceneDescriptions: [String] = []
    
    @State private var commentTimes: [Double] = []
    @State private var commentDescriptions: [String] = []
    
    @State private var audioTimes: [Double] = [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 90.0, 91.0]
    @State private var audioPitches: [Double] = [1, 2, 3, 2, 1, 0, 1, 3, 2, 3, 4]

    @State private var vibrationTimes: [Double] = [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 90.0, 91.0]
    @State private var vibrationIntensity: [Double] = [1, 2, 3, 2, 1, 0, 1, 3, 2, 3, 4]
    @State private var vibrationDescriptions: [String] = []
    
//    @State private var favoriteTopics: Set<Int> = []
    
    
//    @State private var audioVolumes1: [Float] = [1.0, 0.5, 0.3]
//    @State private var audioVolumes2: [Float] = [0.3, 1.0, 0.5]
//    @State private var audioVolumes3: [Float] = [0.5, 0.3, 1.0]
    
    init() {
        let videoURL = Bundle.main.url(forResource: "video", withExtension: "mp4")!
        _player = State(initialValue: AVPlayer(url: videoURL))
    }
    
    var body: some View {
        VStack {
            VideoPlayerView(player: $player)
                .onAppear {
                    configureAudioSession()
                    prepareHaptics()
                    setupPlayer()
                    loadCSV(fileName: "scenes", descriptionKey: "description", timeKey: "time\r", descriptions: $sceneDescriptions, times: $sceneTimes)
                    loadCSV(fileName: "comments", descriptionKey: "description", timeKey: "time\r", descriptions: $commentDescriptions, times: $commentTimes)                }
            
//            Button(action: {
//                addFavoriteTopic()
//            }) {
//                Text("Add to Favorites")
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
//            .padding()
            
            Slider(value: Binding(
                get: { self.mySliderValue },
                set: { (newValue) in
                    self.mySliderValue = newValue
//                    let currentVolumeIndex = Int((newValue / self.videoDuration) * Double(self.audioVolumes1.count))
//                    audioPlayerManager.updateAudioVolumes(index: currentVolumeIndex, audioVolumes1: audioVolumes1, audioVolumes2: audioVolumes2, audioVolumes3: audioVolumes3)
                    player.seek(to: CMTime(seconds: newValue, preferredTimescale: 1))
                }
            ), in: 0...videoDuration, onEditingChanged: handleSliderEditingChanged)
            .accessibilityValue("")//remove the default value announcement in VoiceOver
            .padding()
            
            
            NavigationStack {
                SceneListView(sceneDescriptions: sceneDescriptions, sceneTimes: sceneTimes, player: $player)
            }
        }
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }

    
    private func setupPlayer() {
        guard let currentItem = player.currentItem else { return }
        Task {
            let duration = try await currentItem.asset.load(.duration)
            self.videoDuration = CMTimeGetSeconds(duration)
        }
        
        let interval = CMTime(seconds: 1, preferredTimescale: 1)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            if !self.isDraggingSlider {
                self.mySliderValue = time.seconds
            }
            checkForVibrationTrigger()
        }
    }
    
    
    private func loadCSV(fileName: String, descriptionKey: String, timeKey: String, descriptions: Binding<[String]>, times: Binding<[Double]>) {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "csv") else {
            print("CSV file not found")
            return
        }

        do {
            let csvData = try String(contentsOfFile: path)
            let rows = csvData.components(separatedBy: "\n").filter { !$0.isEmpty }
            let headers = rows[0].components(separatedBy: ",")
            guard headers.count == 2, headers[0] == descriptionKey, headers[1] == timeKey else {
                print("CSV file format is incorrect")
                return
            }
            var localDescriptions: [String] = []
            var localTimes: [Double] = []
            for row in rows.dropFirst() {
                let columns = row.components(separatedBy: ",")
                if columns.count == 2,
                   let description = columns.first?.trimmingCharacters(in: .whitespacesAndNewlines),
                   let timeString = columns.last?.trimmingCharacters(in: .whitespacesAndNewlines),
                   let time = Double(timeString) {
                    localDescriptions.append(description)
                    localTimes.append(time)
                }
            }
            DispatchQueue.main.async {
                descriptions.wrappedValue = localDescriptions
                times.wrappedValue = localTimes
            }
        } catch {
            print("Error reading CSV file: \(error)")
        }
    }
    
    private func handleSliderEditingChanged(_ editing: Bool) {
        if editing {
            self.isDraggingSlider = true
            self.wasPlayingBeforeDrag = player.rate != 0
            player.pause()
//            audioPlayerManager.startAudio()
            
            self.stableCount = 0.0
            self.lastSliderValue = self.mySliderValue
            startStableTimer()
        } else {
            self.isDraggingSlider = false
//            audioPlayerManager.stopAudio()
            if self.wasPlayingBeforeDrag {
                player.play()
            }
            self.stableCount = 0.0
        }
    }
    
    private func startStableTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !self.isDraggingSlider {
                synthesizer.stopSpeaking(at: .immediate)
                self.isSpeaking = false
                timer.invalidate()
                return
            }
            if abs(self.mySliderValue - self.lastSliderValue) > 2 {
                self.stableCount = 0.0
                synthesizer.stopSpeaking(at: .immediate)
                self.isSpeaking = false
            } else {
                self.stableCount += 0.1
                if self.stableCount > 1.0 && !self.isSpeaking {
                    self.isSpeaking = true
                    self.startSpeechSynthesis()
                }
            }
            checkForAudioTrigger()
            self.lastSliderValue = self.mySliderValue
        }
    }
    
    private func checkForAudioTrigger() {
        for index in audioTimes.indices {
            if (self.mySliderValue - audioTimes[index]) * (audioTimes[index] - self.lastSliderValue) > 0 {
                audioEngineManager.playSound(pitch: 3 * audioPitches[index], duration: 0.2)
                return
            }
        }
    }

    private func startSpeechSynthesis() {
        guard !commentTimes.isEmpty else { return }
        
        DispatchQueue.global().async {
            for index in commentTimes.indices {
                guard self.isSpeaking else { break }
                if commentTimes[index] > self.mySliderValue {
                    let utterance = AVSpeechUtterance(string: self.commentDescriptions[index])
                    utterance.rate = 0.8
                    utterance.volume = 1.0
                    utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
                    self.synthesizer.speak(utterance)
                    while self.synthesizer.isSpeaking {
                        usleep(100000)
                    }
                }
            }
        }
    }
    
    private func prepareHaptics() {
        do {
            self.hapticEngine = try CHHapticEngine()
            try self.hapticEngine?.start()
        } catch {
            print("Haptic engine failed to start: \(error.localizedDescription)")
        }
    }
    
//    private func addFavoriteTopic() {
//        if let lastIndex = vibrationTimes.lastIndex(where: { $0 < self.mySliderValue }) {
//            favoriteTopics.insert(lastIndex)
//            print("Added favorite topic at index \(lastIndex)")
//        }
//    }
    
    private func checkForVibrationTrigger() {
        guard player.rate != 0 else { return }
        
        if let i1 = vibrationTimes.lastIndex(where: { $0 < self.mySliderValue }){
            if let i2 = vibrationTimes.firstIndex(where: { $0 > self.lastSliderValue }){
                if i1 == i2{
                    print("slider=\(self.mySliderValue)")
                    print("last_slider=\(self.lastSliderValue)")
                    print(i1)
                    triggerVibration(intensity: vibrationIntensity[i1])
                }
            }
        }
        self.lastSliderValue = self.mySliderValue
   }
    
    private func triggerVibration(intensity: Double) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        let intensityParameter = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity))
        let sharpnessParameter = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParameter, sharpnessParameter], relativeTime: 0)

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
            print("Playing Vibration")
        } catch {
            print("Failed to play haptic: \(error.localizedDescription)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
