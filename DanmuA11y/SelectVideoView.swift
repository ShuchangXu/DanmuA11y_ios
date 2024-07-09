//
//  SelectVideoView.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/7/9.
//

import SwiftUI

struct SelectVideoView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedVideo: String? = nil
    
    let videoDirectories = ["video1"]
    
    var body: some View {
        NavigationStack {
            List(videoDirectories, id: \.self) { video in
                NavigationLink(destination: ContentView(videoDirectory: video)
                                .environmentObject(dataManager)
                                .navigationBarBackButtonHidden(true)) {
                    Text(video)
                }
            }
            .navigationTitle("Select a Video")
        }
        
//        List(videoDirectories, id: \.self) { video in
            
//            NavigationLink(destination: ContentView(videoDirectory: video)
//                    .environmentObject(dataManager)
////                    .navigationBarBackButtonHidden(true)
//            ) {
//                Text(video)
//            }
//        }
//        .navigationTitle("Select a Video")
    }
}

struct SelectVideoView_Previews: PreviewProvider {
    static var previews: some View {
        SelectVideoView()
            .environmentObject(DataManager())
    }
}
