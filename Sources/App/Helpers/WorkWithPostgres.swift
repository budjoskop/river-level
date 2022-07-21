//
//  WorkWithPostgres.swift
//  
//
//  Created by Ognjen Tomic on 21.7.22..
//

import Vapor
import FluentPostgresDriver

final class WorkWithPostgres {

//    let databaseConfig = PostgresConfiguration(hostname: "localhost", port: 5432, username: "username", password: nil, database: "testestest")
//
//    let database: PostgresDatabase
//
//    static let shared = WorkWithPostgres()
//
//    private init() {
//
//    }
//
////    func readAll<T: PostgresDatabase>(postgreSQLModel: T.Type, completion: (([T]) -> Void)?) {
////        let worker = MultiThreadedEventLoopGroup(numberOfThreads: 1)
////        let conn = database.newConnection(on: worker)
////
////        let _ = conn.map { connection in
////            postgreSQLModel.query(on: connection).all().map { databaseData in
////                worker.shutdownGracefully { _ in
////                }
////
////                completion?(databaseData)
////            }
////        }
////    }
//
//    func create<T: PostgreSQLModel>(postgreSQLModel: T) {
//        let worker = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        let conn = database.newConnection(on: worker)
//
//        let _ = conn.map { connection in
//            let _ = postgreSQLModel.save(on: connection).whenComplete {
//                worker.shutdownGracefully { _ in
//                }
//            }
//        }
//    }
    
    static let shared = WorkWithPostgres()
    
    func saveIt(_ app: Application, input: String) throws {
        
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database"
        ), as: .psql)
        

    }

}
