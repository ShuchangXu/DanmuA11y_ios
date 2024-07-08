//
//  SubListView.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/6/29.
//

import SwiftUI
import AVKit

struct SubListView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var player: AVPlayer
    
    var danmu_ids: [Int]
    
    var body: some View {
        List {
            
            ForEach(danmu_ids, id: \.self) { danmu_id in
                Button(action: {
                    player.seek(to: CMTime(seconds: dataManager.danmuList[danmu_id - 1].timestamp, preferredTimescale: 1))
                }) {
                    Text(dataManager.danmuList[danmu_id - 1].text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
