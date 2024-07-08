//
//  SceneListView.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/6/29.
//

import SwiftUI
import AVKit

struct TopicListView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var player: AVPlayer
    
    var body: some View {
        List {
            ForEach(dataManager.topicList.indices, id: \.self) { index in
                HStack {
                    Button(action: {
//                        player.seek(to: CMTime(seconds: topics[index], preferredTimescale: 1))
                    }) {
                        Text(dataManager.topicList[index].summary + dataManager.topicList[index].context)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.7)
                    NavigationLink(destination: SubListView(player: $player, danmu_ids: dataManager.topicList[index].danmu_id_list).environmentObject(dataManager)) {
                    }.accessibilityLabel("共"+String(dataManager.topicList[index].heat)+"弹幕, 双击查看")
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
