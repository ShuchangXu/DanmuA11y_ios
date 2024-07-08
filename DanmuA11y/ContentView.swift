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
    
    @State private var sceneTimes: [Double] = []
    @State private var sceneDescriptions: [String] = []
    @State private var sceneHeat: [Int] = [1, 2, 3, 2, 1, 0, 1, 3, 2, 3, 4]
    
    @State private var selectedL1: L1? = nil
    @State private var selectedL2: L2? = nil
    @State private var selectedTopics: [Int] = []

    
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
                    dataManager.loadData(videoName: "video5")
//                    loadCSV(fileName: "scenes", descriptionKey: "description", timeKey: "time\r", descriptions: $sceneDescriptions, times: $sceneTimes)
                }
            
//            VStack {
//                // Example usage of DataManager functions
//                Text("L2 Themes for L1 ID 1: \(arrayToString(dataManager.filterL2ByL1Id(l1Id: 1)))")
//                Text("Topics for L1 ID 1 and L2 ID 2: \(arrayToString(dataManager.filterTopicsByL1AndL2Id(l1Id: 1, l2Id: 2)))")
//                Text("Scene ID for Time 10.0: \(dataManager.filterSceneByTime(time: 10.0) ?? -1)")
//                Text("Topics for L1 ID 1, L2 ID 2, and Scene ID 1: \(topicsToString(dataManager.filterTopicsByL1L2SceneId(l1Id: 1, l2Id: 2, sceneId: 1)))")
//                Text("Danmu for Topic ID 1: \(danmuToString(dataManager.filterDanmuByTopicId(topicId: 1)))")
//            }
//            .onAppear {
//
//            }
            
            NavigationStack {
                TopicListView(player: $player)
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
                                    Text("话题\(l1.L1_theme_id).\(l2.L2_theme_id)" + l2.L2_sum)
                                }
                            }
                        } label: {
                            Text("类别\(l1.L1_theme_id)" + l1.L1_sum)
                        }
                    }
                    
                    Button(action: {
                        selectedL1 = nil
                        selectedL2 = nil
                        selectedTopics = []
                    }) {
                        Text("全部话题")
                    }
                    
                } label: {
                    Text(selectedL1 == nil ? "全部话题" : "话题\(selectedL1!.L1_theme_id).\(selectedL2?.L2_theme_id ?? 0) \(selectedL1!.L1_sum) - \(selectedL2?.L2_sum ?? "")")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 100)
        }
    }
    
    private func arrayToString(_ array: [Int]?) -> String {
        guard let array = array else { return "[]" }
        return array.map { String($0) }.joined(separator: ", ")
    }

    private func topicsToString(_ topics: [Topic]?) -> String {
        guard let topics = topics else { return "[]" }
        return topics.map { "\($0.topic_id)" }.joined(separator: ", ")
    }

    private func danmuToString(_ danmus: [Danmu]?) -> String {
        guard let danmus = danmus else { return "[]" }
        return danmus.map { "\($0.danmu_id)" }.joined(separator: ", ")
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
        for index in sceneTimes.indices {
            if (self.mySliderValue - sceneTimes[index]) * (sceneTimes[index] - self.lastSliderValue) > 0 {
                audioEngineManager.playSound(pitch: Double(3 * sceneHeat[index]), duration: 0.2)
                return
            }
        }
    }

    private func startSpeechSynthesis() {
        guard !sceneTimes.isEmpty else { return }
        
        DispatchQueue.global().async {
            for index in sceneTimes.indices {
                guard self.isSpeaking else { break }
                if sceneTimes[index] > self.mySliderValue {
                    let utterance = AVSpeechUtterance(string: self.sceneDescriptions[index])
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
    
    private func checkForVibrationTrigger() {
        guard player.rate != 0 else { return }
        
        if let i1 = sceneTimes.lastIndex(where: { $0 < self.mySliderValue }){
            if let i2 = sceneTimes.firstIndex(where: { $0 > self.lastSliderValue }){
                if i1 == i2{
                    print("slider=\(self.mySliderValue)")
                    print("last_slider=\(self.lastSliderValue)")
                    print(i1)
                    triggerVibration(intensity: Double(sceneHeat[i1]))
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
