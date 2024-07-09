//
//  SceneListView.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/6/29.
//

import SwiftUI
import AVKit

struct TopicListView: View {
    @Binding var selectedTopics: [Int]
    @Binding var player: AVPlayer
    @Binding var currentTime: Double
    @Binding var isUserScrolling: Bool
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(dataManager.getTopicsByScene(selectedTopics: selectedTopics), id: \.sceneID) { sceneID, topics in
                    if let scene = dataManager.sceneList.first(where: { $0.scene_id == sceneID }) {
                        VStack {
                            Button(action: {
                                player.seek(to: CMTime(seconds: scene.start, preferredTimescale: 1))
                            }) {
                                Text("场景\(scene.scene_id): \(scene.avscript)")
                                    .font(.headline)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.blue)
                                    .padding(.vertical, 8)
                                    .accessibilityLabel("场景\(scene.scene_id): \(scene.avscript)")
                            }.buttonStyle(BorderlessButtonStyle())
                            ForEach(Array(topics.sorted(by: { $0.heat > $1.heat }).enumerated()), id: \.element.topic_id) { index, topic in
                                let danmuTexts = topic.danmu_id_list.compactMap { danmuID in
                                    dataManager.danmuList.first(where: { $0.danmu_id == danmuID })?.text
                                }.joined(separator: "。")
                                NavigationLink(destination: SubListView(danmuList: dataManager.getDanmus(for: topic.danmu_id_list), player: $player)){
                                    HStack {
                                        Text("话题\(index + 1). ")
                                            + Text(topic.context == "_" ? "" : "因" + topic.context + ", ").foregroundColor(.blue)
                                            + Text(topic.summary)
                                    }
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                                    .accessibilityLabel("话题\(scene.scene_id).\(index + 1). \((topic.context == "_" ? "" : "因为" + topic.context + ",")), \(topic.summary). 共\(topic.heat)条。原文: \(danmuTexts)")
                                }
                            }
                        }
                        .id(sceneID) // 给每个 section 设置一个唯一的 id
                    }
                }
            }
            .onChange(of: currentTime) { newTime in
                scrollToCurrentScene(proxy: proxy)
            }
            .onChange(of: selectedTopics) { _ in
                dataManager.updateSceneData(for: selectedTopics)
                scrollToCurrentScene(proxy: proxy)
            }
        }
    }

    private func scrollToCurrentScene(proxy: ScrollViewProxy) {
        if let currentScene = dataManager.sceneList.first(where: { $0.start <= currentTime && currentTime < $0.end }) {
            withAnimation {
//                print(currentScene.scene_id)
                proxy.scrollTo(currentScene.scene_id, anchor: .top)
            }
        }
    }
}

struct SubListView: View {
    var danmuList: [Danmu]
    @Binding var player: AVPlayer

    var body: some View {
        List(danmuList, id: \.danmu_id) { danmu in
            Button(action: {
                player.seek(to: CMTime(seconds: danmu.timestamp, preferredTimescale: 1))
            }) {
                Text(danmu.text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
