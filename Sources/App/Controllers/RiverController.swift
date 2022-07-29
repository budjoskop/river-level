//
//  RiverController.swift
//
//
//  Created by Ognjen Tomic on 19.7.22..
//

import Foundation
import Vapor
import SWXMLHash
import PostgresNIO
#if canImport(FoundationNetworking)
import FoundationNetworking
import FluentKit
#endif




struct RiverController: RouteCollection {
    
    
    let dateFormater = DateFormatter()
    
    func boot(routes: RoutesBuilder) throws {
       
        
        let protected = routes.grouped(UserAuthenticator())
        protected.get("rivers") { req -> EventLoopFuture<RiverPresentation> in
            req.logger.info("🥁 GET request for Rivers init 🥁")
            print(try req.auth.require(User.self).name)
            return try readIndex(req: req)
        }
            

        protected.post("save") { req -> EventLoopFuture<RiverPresentation> in
            req.logger.info("🎯 POST request to save in DB init 🎯")
            
            dateFormater.dateFormat = "MM-dd-yyyy HH:mm"
            
            let dateString = dateFormater.string(from: Date())
            let date = dateFormater.date(from: dateString)
            print(try req.auth.require(User.self).name)
            let riverName = RiverPresentation(id: nil, river: [River](), dateCreation: date!)
            riverName.rivers = fetchXml()
            riverName.dateCreation = date!
            print(riverName.dateCreation)
            req.logger.info("✅ success ✅")
            
            return riverName.save(on: req.db).map {
                riverName
            }
        }
    }

    
    
    
    //GET Request /rivers route
    func readIndex(req: Request) throws -> EventLoopFuture<RiverPresentation> {
        
        // logic bellow is to extract single item from RiverPresentation array
        var cheatArray = [EventLoopFuture<RiverPresentation>]()
        let entireArray = RiverPresentation.query(on: req.db).sort(\.$dateCreation).all()
       

        let lastItem =  entireArray.map { array in
            array.last
        }
        req.logger.notice("✅ THIS IS LAST ITEM IN ARRAY: \(lastItem) ✅")

        cheatArray.append(lastItem.unwrap(orElse: {
            RiverPresentation(river: [], dateCreation: Date())
        }))
        
        return cheatArray[0]
        
    }
    
    
    
    // Fetch XML from RHMZZ
    func fetchXml() -> [River] {
        print("🎬 Fetch XML in progress 🎬")
        // fetch xml here from url
        let urlString: String = "https://www.hidmet.gov.rs/latin/prognoza/prognoza_voda.xml"
        let url = URL(string: urlString)
        let data: Data?
        
        do {
            data = try Data(contentsOf: url!)
            let xml = XMLHash.parse(data!)
            let xmlForParse = xml["feed"]["entry"].all
            let meassurments: [String] = []
            var rivers:[River] = []
           
            
            rivers = nodeForParse(riverName: "DUNAV", meassures: meassurments, xmlForParse: xmlForParse)
            rivers.append(contentsOf: nodeForParse(riverName: "SAVA", meassures: meassurments, xmlForParse: xmlForParse))
            rivers.append(contentsOf: nodeForParse(riverName: "TISA", meassures: meassurments, xmlForParse: xmlForParse))
            rivers.append(contentsOf: nodeForParse(riverName: "VELIKA MORAVA", meassures: meassurments, xmlForParse: xmlForParse))
            rivers.append(contentsOf: nodeForParse(riverName: "ZAPADNA MORAVA", meassures: meassurments, xmlForParse: xmlForParse))
            rivers.append(contentsOf: nodeForParse(riverName: "JUŽNA MORAVA", meassures: meassurments, xmlForParse: xmlForParse))

            
            let jsonEncoder = JSONEncoder()
            let jsonDecoder = JSONDecoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            do {
                let jsonData = try jsonEncoder.encode(rivers)
                let riverStruct =  try jsonDecoder.decode([River].self, from: jsonData)
                return riverStruct
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
        return [River]()
    }
    
    
    // Helper function for XML parsing
    func nodeForParse(riverName: String, meassures: [String], xmlForParse: [XMLIndexer]) -> [River]  {
        
        var helperMeassure = meassures
        var riverDetails:[RiverDetails] = []
        var river = River(
            riverName: "",
            riverDetails: []
        )
        var rivers:[River] = []
        
        for nodeElement in xmlForParse {
            
            let title = nodeElement["title"].element!.text
            if title.contains(riverName) {
                let x = title.components(separatedBy: "-")[0] // rivername from splited string
                let riverName = x.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)
                let y = title.components(separatedBy: "-")[1]
                let riverPlace = y.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)
                
                let summary = nodeElement["summary"].element!.text

                let summaryElements = summary.components(separatedBy: ";")
                helperMeassure = summaryElements.filter {$0 != " "}
            
                var levelsPerRiver: [RiverLevel] = []
                var levels = [String]()
                var dates = [String]()
                
                for index in 0 ... helperMeassure.count - 1 {
                    let matched = matchRegexPattern(for: "\\d{1,}.\\d{2}", in: helperMeassure[index])
                    
                    if !matched.isEmpty {
                        
                        let date = Date()
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy"
                        let yearString = dateFormatter.string(from: date)
                        
                        let dateStringFormated = matched[0]+".\(yearString)"
                        dates.append(dateStringFormated)
                    }
                }
               
                let totalDatesCOUNT = helperMeassure.count

                levelsPerRiver = [RiverLevel](repeating: RiverLevel(date: "", level: ""), count: totalDatesCOUNT)
                
                for index in 0 ... dates.count - 1 {
                    
                    levelsPerRiver[index].date = dates[index]
                }
                
                
                for index in 0 ... helperMeassure.count - 1 {
                    let matched = matchRegexPattern(for: "\\-?\\d{1,} cm", in: helperMeassure[index])
                    if !matched.isEmpty {
                        levels.append(matched[0])
                    }
                }
                
                
                for index in 0 ... levels.count - 1 {
                    levelsPerRiver[index].level = levels[index]
                }
                
                
                riverDetails.append(
                    RiverDetails(
                        place: riverPlace,
                        meassurmentDetails: levelsPerRiver
                    )
                )
                
                
                river = River(
                    riverName: riverName,
                    riverDetails: riverDetails
                )

            }
            
            
        }
        riverDetails = []
        
        rivers.append(river)
        
        return rivers

    }
    
    
    // Regex function for matching
    func matchRegexPattern(for regex: String, in text: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    
}




extension Data: AsyncResponseEncodable {

    public func encodeResponse(for request: Request) async throws -> Response {
        print("OVDE NESTO DESAVA")
        let response = Response.init()
        print(response)
        return response

    }
}


extension Date {
    func getFormattedDate(format: String, inputString: String) -> String {
        // Create String
        let string = inputString

        // Create Date Formatter
        let dateFormatter = DateFormatter()

        // Set Date Format
        dateFormatter.dateFormat = format

        // Convert String to Date
        let date = dateFormatter.date(from: string)
       
        
        return dateFormatter.string(from: date!)
    }
}
