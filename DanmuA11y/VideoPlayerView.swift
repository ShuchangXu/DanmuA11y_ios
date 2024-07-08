//
//  VideoPlayerView.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/6/29.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @Binding var player: AVPlayer
    
    var body: some View {
        VideoPlayer(player: player)
            .frame(height: 270) // Adjust the height as needed
    }
}
