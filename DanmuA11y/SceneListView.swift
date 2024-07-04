//
//  SceneListView.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/6/29.
//

import SwiftUI
import AVKit

struct SceneListView: View {
    var sceneDescriptions: [String]
    var sceneTimes: [Double]
    @Binding var player: AVPlayer
    
    var body: some View {
        List {
            ForEach(sceneDescriptions.indices, id: \.self) { index in
                HStack {
                    Button(action: {
//                        print("timeChange")
                        player.seek(to: CMTime(seconds: sceneTimes[index], preferredTimescale: 1))
//                        player.play()
                    }) {
                        Text(sceneDescriptions[index])
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.7)
                    NavigationLink(destination: SubListView()) {
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
