//
//  DataModel.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/7/7.
//

import Foundation

struct L1Theme {
    var id: Int
    var summary: String
    var l2ThemeList: [Int]
}

struct L2Theme {
    var id: Int
    var summary: String
    var tri: String
    var topics: [Int]
    var scenes: [Int]
}

struct Scene {
    var id: Int
    var start: Double
    var end: Double
    var avscript: String
    var transcripts: String
}

struct Topic {
    var id: Int
    var summary: String
    var context: String
    var danmuIdList: [Int]
    var sceneId: Int
    var heat: Int
}

struct Danmu {
    var timestamp: Double
    var text: String
    var sceneId: Int
    var id: Int
}

func readCSV(fileName: String) -> [[String]] {
    var csvArray = [[String]]()
    if let path = Bundle.main.path(forResource: fileName, ofType: "csv") {
        do {
            let data = try String(contentsOfFile: path)
            let rows = data.components(separatedBy: "\n").filter { !$0.isEmpty }
            for row in rows {
                let columns = row.components(separatedBy: ",")
                csvArray.append(columns)
            }
        } catch {
            print("Error reading CSV file: \(error)")
        }
    }
    return csvArray
}

func parseL1(csvData: [[String]]) -> [L1Theme] {
    var l1Themes = [L1Theme]()
    for row in csvData.dropFirst() {
        if let id = Int(row[0]),
           let l2ThemeListData = row[2].data(using: .utf8),
           let l2ThemeList = try? JSONDecoder().decode([Int].self, from: l2ThemeListData) {
            let theme = L1Theme(id: id, summary: row[1], l2ThemeList: l2ThemeList)
            l1Themes.append(theme)
        }
    }
    return l1Themes
}

func parseL2(csvData: [[String]]) -> [L2Theme] {
    var l2Themes = [L2Theme]()
    for row in csvData.dropFirst() {
        if let id = Int(row[0]),
           let topicsData = row[3].data(using: .utf8),
           let topics = try? JSONDecoder().decode([Int].self, from: topicsData),
           let scenesData = row[4].data(using: .utf8),
           let scenes = try? JSONDecoder().decode([Int].self, from: scenesData) {
            let theme = L2Theme(id: id, summary: row[1], tri: row[2], topics: topics, scenes: scenes)
            l2Themes.append(theme)
        }
    }
    return l2Themes
}

func parseScenes(csvData: [[String]]) -> [Scene] {
    var scenes = [Scene]()
    for row in csvData.dropFirst() {
        if let id = Int(row[0]),
           let start = Double(row[1]),
           let end = Double(row[2]) {
            let scene = Scene(id: id, start: start, end: end, avscript: row[3], transcripts: row[4])
            scenes.append(scene)
        }
    }
    return scenes
}

func parseTopics(csvData: [[String]]) -> [Topic] {
    var topics = [Topic]()
    for row in csvData.dropFirst() {
        if let id = Int(row[0]),
           let danmuIdListData = row[3].data(using: .utf8),
           let danmuIdList = try? JSONDecoder().decode([Int].self, from: danmuIdListData),
           let sceneId = Int(row[4]),
           let heat = Int(row[5]) {
            let topic = Topic(id: id, summary: row[1], context: row[2], danmuIdList: danmuIdList, sceneId: sceneId, heat: heat)
            topics.append(topic)
        }
    }
    return topics
}

func parseDanmu(csvData: [[String]]) -> [Danmu] {
    var danmus = [Danmu]()
    for row in csvData.dropFirst() {
        if let timestamp = Double(row[0]),
           let sceneId = Int(row[2]),
           let id = Int(row[3]) {
            let danmu = Danmu(timestamp: timestamp, text: row[1], sceneId: sceneId, id: id)
            danmus.append(danmu)
        }
    }
    return danmus
}

class CSVDataManager: ObservableObject {
    @Published var l1Themes: [L1Theme] = []
    @Published var l2Themes: [L2Theme] = []
    @Published var scenes: [Scene] = []
    @Published var topics: [Topic] = []
    @Published var danmus: [Danmu] = []
    
    init(vid: String) {
        let l1Data = readCSV(fileName: "\(vid)/\(vid)_l1")
        let l2Data = readCSV(fileName: "\(vid)/\(vid)_l2")
        let sceneData = readCSV(fileName: "\(vid)/\(vid)_scene_all")
        let topicData = readCSV(fileName: "\(vid)/\(vid)_topics")
        let danmuData = readCSV(fileName: "\(vid)/\(vid)_danmu")

        l1Themes = parseL1(csvData: l1Data)
        l2Themes = parseL2(csvData: l2Data)
        scenes = parseScenes(csvData: sceneData)
        topics = parseTopics(csvData: topicData)
        danmus = parseDanmu(csvData: danmuData)
    }
    
    func filterL2ByL1(l1Id: Int) -> [L2Theme] {
        guard let l1Theme = l1Themes.first(where: { $0.id == l1Id }) else {
            return []
        }
        return l2Themes.filter { l1Theme.l2ThemeList.contains($0.id) }
    }

    func filterTopicsByL1AndL2(l1Id: Int, l2Id: Int) -> [Topic] {
        let l2Themes = filterL2ByL1(l1Id: l1Id)
        guard l2Themes.contains(where: { $0.id == l2Id }) else {
            return []
        }
        guard let l2Theme = l2Themes.first(where: { $0.id == l2Id }) else {
            return []
        }
        return topics.filter { l2Theme.topics.contains($0.id) }
    }

    func determineSceneByTime(time: Double) -> Int? {
        for scene in scenes {
            if scene.start <= time && time <= scene.end {
                return scene.id
            }
        }
        return nil
    }

    func filterTopicsByL1L2AndScene(l1Id: Int, l2Id: Int, sceneId: Int) -> [Topic] {
        let l2Themes = filterL2ByL1(l1Id: l1Id)
        guard l2Themes.contains(where: { $0.id == l2Id }) else {
            return []
        }
        guard let l2Theme = l2Themes.first(where: { $0.id == l2Id }) else {
            return []
        }
        return topics.filter { l2Theme.topics.contains($0.id) && $0.sceneId == sceneId }
    }

    func filterDanmuByTopic(topicId: Int) -> [Danmu] {
        guard let topic = topics.first(where: { $0.id == topicId }) else {
            return []
        }
        return danmus.filter { topic.danmuIdList.contains($0.id) }
    }
}
