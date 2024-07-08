//
//  DataManager.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/7/7.
//

import Foundation

struct L1: Identifiable {
    let id = UUID()
    let L1_theme_id: Int
    let L1_sum: String
    let L2_theme_list: [Int]
}

struct L2: Identifiable {
    let id = UUID()
    let L2_theme_id: Int
    let L2_sum: String
    let L2_tri: String
    let topics: [Int]
    let scenes: [Int]
}

struct VidScene {
    let scene_id: Int
    let start: Double
    let end: Double
    let avscript: String
    let transcripts: String
}

struct Topic {
    let topic_id: Int
    let summary: String
    let context: String
    let danmu_id_list: [Int]
    let scene_id: Int
    let heat: Int
}

struct Danmu {
    let timestamp: Double
    let text: String
    let scene_id: Int
    let danmu_id: Int
}

private func parseStringToIntArray(_ string: String) -> [Int] {
    let trimmed = string.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
    let components = trimmed.split(separator: ",")
    return components.map { Int($0.trimmingCharacters(in: .whitespaces))! }
}

// Parsing function for l1.csv
func parseL1CSV(contents: String) -> [L1] {
    var l1List: [L1] = []
    let rows = contents.split(separator: "\n").map { String($0) }
    for row in rows.dropFirst() {
        let columns = row.split(separator: ";").map { String($0) }
        if columns.count >= 3 {
            let l1 = L1(
                L1_theme_id: Int(columns[0])!,
                L1_sum: columns[1],
                L2_theme_list: parseStringToIntArray(columns[2])
            )
            l1List.append(l1)
        }
    }
    return l1List
}

// Parsing function for l2.csv
func parseL2CSV(contents: String) -> [L2] {
    var l2List: [L2] = []
    let rows = contents.split(separator: "\n").map { String($0) }
    for row in rows.dropFirst() {
        let columns = row.split(separator: ";").map { String($0) }
        if columns.count >= 5 {
            let l2 = L2(
                L2_theme_id: Int(columns[0])!,
                L2_sum: columns[1],
                L2_tri: columns[2],
                topics: parseStringToIntArray(columns[3]),
                scenes: parseStringToIntArray(columns[4])
            )
            l2List.append(l2)
        }
    }
    return l2List
}

// Parsing function for scene_all.csv
func parseSceneCSV(contents: String) -> [VidScene] {
    var sceneList: [VidScene] = []
    let rows = contents.split(separator: "\n").map { String($0) }
    for row in rows.dropFirst() {
        let columns = row.split(separator: ";").map { String($0) }
        if columns.count >= 5 {
            let scene = VidScene(
                scene_id: Int(columns[0])!,
                start: Double(columns[1])!,
                end: Double(columns[2])!,
                avscript: columns[3],
                transcripts: columns[4]
            )
            sceneList.append(scene)
        }
    }
    return sceneList
}

// Parsing function for topics.csv
func parseTopicCSV(contents: String) -> [Topic] {
    var topicList: [Topic] = []
    let rows = contents.split(separator: "\n").map { String($0) }
    for row in rows.dropFirst() {
        let columns = row.split(separator: ";").map { String($0) }
        if columns.count >= 6 {
            print(row)
            let topic = Topic(
                topic_id: Int(columns[0])!,
                summary: columns[1],
                context: columns[2],
                danmu_id_list: parseStringToIntArray(columns[3]),
                scene_id: Int(columns[4])!,
                heat: Int(columns[5])!
            )
            topicList.append(topic)
        }
    }
    return topicList
}

// Parsing function for danmu.csv
func parseDanmuCSV(contents: String) -> [Danmu] {
    var danmuList: [Danmu] = []
    let rows = contents.split(separator: "\n").map { String($0) }
    for row in rows.dropFirst() {
        let columns = row.split(separator: ";").map { String($0) }
        if columns.count >= 4 {
            let danmu = Danmu(
                timestamp: Double(columns[0])!,
                text: columns[1],
                scene_id: Int(columns[2])!,
                danmu_id: Int(columns[3])!
            )
            danmuList.append(danmu)
        }
    }
    return danmuList
}

class DataManager: ObservableObject{
    @Published var l1List: [L1] = []
    @Published var l2List: [L2] = []
    @Published var sceneList: [VidScene] = []
    @Published var topicList: [Topic] = []
    @Published var danmuList: [Danmu] = []
    
    // Class function to read CSV files and store data into lists
    func loadData(videoName: String) {
        if let l1Path = Bundle.main.path(forResource: "l1", ofType: "csv", inDirectory:videoName),
           let l1Contents = try? String(contentsOfFile: l1Path) {
            l1List = parseL1CSV(contents: l1Contents)
        }
           
        if let l2Path = Bundle.main.path(forResource: "l2", ofType: "csv", inDirectory:videoName),
           let l2Contents = try? String(contentsOfFile: l2Path) {
            l2List = parseL2CSV(contents: l2Contents)
        }

        if let scenePath = Bundle.main.path(forResource: "scene_all", ofType: "csv", inDirectory:videoName),
           let sceneContents = try? String(contentsOfFile: scenePath) {
            sceneList = parseSceneCSV(contents: sceneContents)
        }

        if let topicPath = Bundle.main.path(forResource: "topics", ofType: "csv", inDirectory:videoName),
           let topicContents = try? String(contentsOfFile: topicPath) {
            topicList = parseTopicCSV(contents: topicContents)
        }

        if let danmuPath = Bundle.main.path(forResource: "danmu", ofType: "csv", inDirectory:videoName),
           let danmuContents = try? String(contentsOfFile: danmuPath) {
            danmuList = parseDanmuCSV(contents: danmuContents)
        }
    }
    
    func getL2List(for l1ID: Int) -> [L2] {
        guard let l1Item = l1List.first(where: { $0.L1_theme_id == l1ID }) else { return [] }
        return l2List.filter { l1Item.L2_theme_list.contains($0.L2_theme_id) }
    }
    
//    // Filtering functions
//    func filterL2ByL1Id(l1Id: Int) -> [Int]? {
//        return l1List.first { $0.L1_theme_id == l1Id }?.L2_theme_list
//    }
//
//    func filterTopicsByL1AndL2Id(l1Id: Int, l2Id: Int) -> [Int]? {
//        guard let l2 = l2List.first(where: { $0.L2_theme_id == l2Id }) else {
//            return nil
//        }
//        return l2.topics
//    }

    func filterSceneByTime(time: Double) -> Int? {
        return sceneList.first { $0.start <= time && $0.end >= time }?.scene_id
    }

//    func filterTopicsByL1L2SceneId(l1Id: Int, l2Id: Int, sceneId: Int) -> [Topic]? {
//        return topicList.filter { $0.scene_id == sceneId }
//    }
}
