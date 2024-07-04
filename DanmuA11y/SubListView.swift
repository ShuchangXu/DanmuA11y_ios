//
//  SubListView.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/6/29.
//

import SwiftUI

struct SubListView: View {
    var body: some View {
        List {
            Text("这是第1条弹幕")
            Text("这是第2条弹幕")
            Text("这是第3条弹幕")
        }
        .frame(maxWidth: .infinity)
    }
}
