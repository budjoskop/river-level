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



struct RiverController: RouteCollection {
    
    

    
    func boot(routes: RoutesBuilder) throws {
       
        
        let protected = routes.grouped(UserAuthenticator())
        protected.get("rivers") { req -> EventLoopFuture<RiverPresentation> in
            print("🥁 GET request for Rivers init 🥁")
            print(try req.auth.require(User.self).name)
            return try readIndex(req: req)
        }
            

        protected.post("save") { req -> EventLoopFuture<RiverPresentation> in
            print("🎯 POST request to save in DB init 🎯")
            print(try req.auth.require(User.self).name)
            let riverName = RiverPresentation(id: nil, river: [River](), dateCreation: Date())
            riverName.river = fetchXml()
            print("✅ success ✅")
            return riverName.save(on: req.db).map {
                riverName
            }
        }
    }


    
    //GET Request /rivers route
    func readIndex(req: Request) throws -> EventLoopFuture<RiverPresentation> {
        
        // logic bellow is to extract single item from RiverPresentation array
        var cheatArray = [EventLoopFuture<RiverPresentation>]()
        let singleItem = RiverPresentation.query(on: req.db).first().unwrap {
            RiverPresentation()
        }
        cheatArray.append(singleItem)
        return cheatArray[0]
    }
    
    
    
    
    // Fetch XML from RHMZZ
    func fetchXml() -> [River] {
        print("🎬 Fetch XML in progress 🎬")
        // fetch xml here from url
        let urlString: String = "https://www.hidmet.gov.rs/latin/prognoza/prognoza_voda.xml"
        let url = URL(string: urlString)
        let urlRequest = URLRequest(url: url!)
//        let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
        let data: Data?
        
        do {
            data = try Data(contentsOf: url!)
//            print("Some response here: \(data)")
    //        if let httpResponse = urlResponse as? HTTPURLResponse {
    //            print("🥁 This is http status: \(httpResponse.statusCode) 🥁")
    //        }
            let xml = XMLHash.parse(data!)
//            print("nova provera da li je nil: \(xml)")
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
            let jsonString: String?
            jsonEncoder.outputFormatting = .prettyPrinted
            do {
                let jsonData = try jsonEncoder.encode(rivers)
                 jsonString = String(
                    data: jsonData,
                    encoding: String.Encoding.utf8
                )!
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
                        dates.append(matched[0])
                    }
                }
               
                let totalDatesCOUNT = helperMeassure.count

                levelsPerRiver = [RiverLevel](repeating: RiverLevel(date: "", level: ""), count: totalDatesCOUNT)
//                print("Total count: \(dates.count), total levelsPerRiver count: \(levelsPerRiver.count)")
                
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
                        measurmentPlace: levelsPerRiver
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


