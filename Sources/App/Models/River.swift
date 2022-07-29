//
//  River.swift
//
//
//  Created by Ognjen Tomic on 14.7.22..
//

import Fluent
import Vapor


// MARK: - Welcomeimport Foundation

struct River: Codable {
    

    
    var riverName: String?
    var riverDetails: [RiverDetails]?
    var id = UUID()
    
    
    enum CodingKeys: String, CodingKey {
        case riverName
        case riverDetails
    }
}

struct RiverDetails: Codable {
    var place: String?
    var meassurmentDetails: [RiverLevel]?
    var id = UUID()
    
    enum CodingKeys: String, CodingKey {
        case place
        case meassurmentDetails
        
    }
}


struct RiverLevel: Codable {
    var date: String?
    var level: String?
    var id = UUID()
    
    enum CodingKeys: String, CodingKey {
        case date
        case level
    }
    
    
}



final class RiverPresentation: Model, Content {
  // 2
  static let schema = "levels"
  
  // 3
  @ID
  var id: UUID?
    
    @Field(key: "dateCreation")
    var dateCreation: Date
  
  // 4
  @Field(key: "rivers")
  var rivers: [River]
    
    init() {}
    
    init(id: UUID? = nil, river: [River], dateCreation: Date) {
        
        let dateFormater = DateFormatter()
        dateFormater.timeZone = TimeZone.current
        dateFormater.dateFormat = "MM-dd-yyyy HH:mm"
        let dateString = dateFormater.string(from: Date())
        let date = dateFormater.date(from: dateString)
        print("this is a date for saving: \(date)")
        
        self.id = id
        self.rivers = river
        self.dateCreation = date!
        
    }
}


