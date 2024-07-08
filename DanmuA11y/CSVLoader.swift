//
//  CSVLoader.swift
//  DanmuA11y
//
//  Created by 许书畅 on 2024/7/7.
//

import Foundation

class CSVLoader {
    static func load<T: Codable>(from fileName: String, as type: T.Type) -> [T] {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "csv") else {
            print("CSV file \(fileName) not found")
            return []
        }
        
        do {
            let csvData = try String(contentsOfFile: path)
            let rows = csvData.components(separatedBy: "\n").filter { !$0.isEmpty }
            let headers = rows[0].components(separatedBy: ",")
            var data: [T] = []
            let decoder = CSVDecoder()
            
            for row in rows.dropFirst() {
                let columns = row.components(separatedBy: ",")
                let jsonData = try JSONSerialization.data(withJSONObject: columns, options: [])
                let decodedObject = try decoder.decode(T.self, from: jsonData)
                data.append(decodedObject)
            }
            
            return data
        } catch {
            print("Error reading CSV file \(fileName): \(error)")
            return []
        }
    }
}

// Define a simple CSV decoder (can be customized for more complex CSV formats)
class CSVDecoder: JSONDecoder {
    override init() {
        super.init()
    }
}
