//
//  UserAuthenticator.swift
//  
//
//  Created by Ognjen Tomic on 21.7.22..
//

import Vapor


struct UserAuthenticator: BasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        if basic.username == "teamit" && basic.password == "surprizemi" {
            request.auth.login(User(name: "API user is trying to SAVE / GET"))
        }
        return request.eventLoop.makeSucceededFuture(())
   }
}

struct User: Authenticatable {
    var name: String
}
