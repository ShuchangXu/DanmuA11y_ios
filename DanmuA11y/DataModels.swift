//
//  DataModels.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/7/7.
//

import Foundation

// Struct for l1.csv
struct L1Theme: Identifiable, Codable {
    var id: Int
    var sum: String
    var l2ThemeList: [Int]
}

// Struct for l2.csv
struct L2Theme: Identifiable, Codable {
    var id: Int
    var sum: String
    var tri: String
    var topics: [Int]
    var scenes: [Int]
}

// Struct for scene_all.csv
struct Scene: Identifiable, Codable {
    var id: Int
    var start: Double
    var end: Double
    var avscript: String
    var transcripts: String
}

// Struct for topics.csv
struct Topic: Identifiable, Codable {
    var id: Int
    var summary: String
    var context: String
    var danmuIdList: [Int]
    var sceneId: Int
    var heat: Int
}

// Struct for danmu.csv
struct Danmu: Identifiable, Codable {
    var timestamp: Double
    var text: String
    var sceneId: Int
    var id: Int
}

class DataService {
    private var l1Themes: [L1Theme] = []
    private var l2Themes: [L2Theme] = []
    private var scenes: [Scene] = []
    private var topics: [Topic] = []
    private var danmus: [Danmu] = []
    
    init() {
        l1Themes = CSVLoader.load(from: "l1", as: L1Theme.self)
        l2Themes = CSVLoader.load(from: "l2", as: L2Theme.self)
        scenes = CSVLoader.load(from: "scene_all", as: Scene.self)
        topics = CSVLoader.load(from: "topics", as: Topic.self)
        danmus = CSVLoader.load(from: "danmu", as: Danmu.self)
    }
    
    func filterL2Themes(for l1Id: Int) -> [L2Theme] {
        guard let l1Theme = l1Themes.first(where: { $0.id == l1Id }) else { return [] }
        return l2Themes.filter { l1Theme.l2ThemeList.contains($0.id) }
    }
    
    func filterTopics(for l1Id: Int, l2Id: Int) -> [Topic] {
        guard let l2Theme = l2Themes.first(where: { $0.id == l2Id }) else { return [] }
        return topics.filter { l2Theme.topics.contains($0.id) }
    }
    
    func findSceneId(for time: Double) -> Int? {
        return scenes.first { $0.start <= time && $0.end >= time }?.id
    }
    
    func filterTopics(for l1Id: Int, l2Id: Int, sceneId: Int) -> [Topic] {
        guard let l2Theme = l2Themes.first(where: { $0.id == l2Id }),
              let scene = scenes.first(where: { $0.id == sceneId }) else { return [] }
        return topics.filter { l2Theme.topics.contains($0.id) && $0.sceneId == sceneId }
    }
    
    func filterDanmus(for topicId: Int) -> [Danmu] {
        guard let topic = topics.first(where: { $0.id == topicId }) else { return [] }
        return danmus.filter { topic.danmuIdList.contains($0.id) }
    }
}
