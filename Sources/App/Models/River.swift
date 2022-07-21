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
}

struct RiverDetails: Codable {
    var place: String?
    var measurmentPlace: [RiverLevel]
}


struct RiverLevel: Codable {
    var date: String?
    var level: String?
}



final class RiverPresentation: Model, Content {
  // 2
  static let schema = "levels"
  
  // 3
  @ID
  var id: UUID?
    
    @Field(key: "dateCreation")
    var dateCreation: Date?
  
  // 4
  @Field(key: "rivers")
  var river: [River]
    
    init() {}
    
    init(id: UUID? = nil, river: [River], dateCreation: Date) {
        self.id = id
        self.river = river
        self.dateCreation = dateCreation
    }
}


