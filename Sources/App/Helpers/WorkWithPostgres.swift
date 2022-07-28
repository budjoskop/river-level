//
//  WorkWithPostgres.swift
//  
//
//  Created by Ognjen Tomic on 21.7.22..
//

import Vapor
import FluentPostgresDriver

final class WorkWithPostgres {
    
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
