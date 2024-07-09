//
//  DanmuA11yApp.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/6/29.
//

import SwiftUI

@main
struct DanmuA11yApp: App {
    var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            SelectVideoView()
                .environmentObject(dataManager)
        }
    }
}
