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
    @EnvironmentObject var dataManager: DataManager
    
    @StateObject private var audioEngineManager = AudioEngineManager()
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var hapticEngine: CHHapticEngine?
    @State private var player: AVPlayer
    @State private var mySliderValue: Double = 0.0
    @State private var videoDuration: Double = 0.0
    
    @State private var lastSliderValue: Double = 0.0
    @State private var isDraggingSlider = false
    @State private var wasPlayingBeforeDrag = false
    @State private var stableCount: Double = 0.0
    @State private var isSpeaking = false
    @State private var isUserScrolling = false
        
    @State private var selectedL1: L1? = nil
    @State private var selectedL2: L2? = nil
    @State private var selectedTopics: [Int] = []

    
    init() {
        let videoURL = Bundle.main.url(forResource: "video", withExtension: "mp4", subdirectory: "video1")!
        _player = State(initialValue: AVPlayer(url: videoURL))
    }
    
    var body: some View {
        VStack {
            VideoPlayerView(player: $player)
                .onAppear {
                    configureAudioSession()
                    prepareHaptics()
                    setupPlayer()
                    dataManager.loadData(videoName: "video1")
                    dataManager.updateSceneData(for: selectedTopics)
                }
            
            NavigationStack {
                TopicListView(selectedTopics: $selectedTopics, player: $player, currentTime: $mySliderValue, isUserScrolling: $isUserScrolling)
                    .environmentObject(dataManager)
            }
            
            Spacer()
            
            Slider(value: Binding(
                get: { self.mySliderValue },
                set: { (newValue) in
                    self.mySliderValue = newValue
                    player.seek(to: CMTime(seconds: newValue, preferredTimescale: 1))
                }
            ), in: 0...videoDuration, onEditingChanged: handleSliderEditingChanged)
            .frame(height: 0)
            .accessibilityValue("")//remove the default value announcement in VoiceOver
            .padding()
                        
            HStack {
                Menu {

                    ForEach(dataManager.l1List.sorted(by: { $0.L1_theme_id > $1.L1_theme_id })) { l1 in
                        Menu {
                            let l2List = dataManager.getL2List(for: l1.L1_theme_id).sorted(by: { $0.L2_theme_id > $1.L2_theme_id })
                            ForEach(l2List) { l2 in
                                Button(action: {
                                    selectedTopics = l2.topics
                                    selectedL1 = l1
                                    selectedL2 = l2
                                }) {
                                    Text("主题\(l1.L1_theme_id).\(l2.L2_theme_id)" + l2.L2_sum)
                                }
                            }
                        } label: {
                            Text("分类\(l1.L1_theme_id)" + l1.L1_sum)
                        }
                    }
                    
                    Button(action: {
                        selectedL1 = nil
                        selectedL2 = nil
                        selectedTopics = []
                    }) {
                        Text("全部主题")
                    }
                    
                } label: {
                    Text(selectedL1 == nil ? "全部主题" : "分类\(selectedL1!.L1_theme_id) \(selectedL1!.L1_sum)\n主题\(selectedL2?.L2_theme_id ?? 0) \(selectedL2?.L2_sum ?? "")")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 80)
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
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    private func handleSliderEditingChanged(_ editing: Bool) {
        if editing {
            self.isDraggingSlider = true
            self.wasPlayingBeforeDrag = player.rate != 0
            player.pause()
            
            self.stableCount = 0.0
            self.lastSliderValue = self.mySliderValue
            startStableTimer()
        } else {
            self.isDraggingSlider = false
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
                if self.stableCount > 0.5 && !self.isSpeaking {
                    self.isSpeaking = true
                    self.speakNextItem()
                }
            }
            checkForAudioTrigger()
            self.lastSliderValue = self.mySliderValue
        }
    }
    
    private func checkForAudioTrigger() {
        for index in dataManager.sceneTimes.indices {
            if (self.mySliderValue - dataManager.sceneTimes[index]) * (dataManager.sceneTimes[index] - self.lastSliderValue) > 0 {
                audioEngineManager.playSound(pitch: Double(dataManager.sceneHeat[index]), duration: 0.2)
                return
            }
        }
    }
    
    private func speakNextItem(){
        guard !dataManager.sceneTimes.isEmpty else { return }
        if let index = dataManager.sceneTimes.lastIndex(where: { $0 < self.mySliderValue }){
            let utterance = AVSpeechUtterance(string: self.dataManager.sceneDescriptions[index])
            utterance.rate = 0.7
            utterance.volume = 1.0
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            self.synthesizer.speak(utterance)
        }
            
    }

//    private func speakAllFollowingItems() {
//        guard !dataManager.sceneTimes.isEmpty else { return }
//        
//        DispatchQueue.global().async {
//            for index in dataManager.sceneTimes.indices {
//                guard self.isSpeaking else { break }
//                if dataManager.sceneTimes[index] > self.mySliderValue {
//                    let utterance = AVSpeechUtterance(string: self.dataManager.sceneDescriptions[index])
//                    utterance.rate = 0.8
//                    utterance.volume = 1.0
//                    utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
//                    self.synthesizer.speak(utterance)
//                    while self.synthesizer.isSpeaking {
//                        usleep(100000)
//                    }
//                }
//            }
//        }
//    }
    
    private func prepareHaptics() {
        do {
            self.hapticEngine = try CHHapticEngine()
            try self.hapticEngine?.start()
        } catch {
            print("Haptic engine failed to start: \(error.localizedDescription)")
        }
    }
    
    private func checkForVibrationTrigger() {
        guard player.rate != 0 else { return }
        
        if let i1 = dataManager.sceneTimes.lastIndex(where: { $0 < self.mySliderValue }){
            if let i2 = dataManager.sceneTimes.firstIndex(where: { $0 > self.lastSliderValue }){
                if i1 == i2{
                    print("slider=\(self.mySliderValue)")
                    print("last_slider=\(self.lastSliderValue)")
                    print(i1)
                    triggerVibration(intensity: Double(dataManager.sceneHeat[i1]))
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
            .environmentObject(DataManager())
    }
}
