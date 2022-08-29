//
//  UserAuthenticator.swift
//  
//
//  Created by Ognjen Tomic on 21.7.22..
//

import Vapor


struct UserAuthenticator: BasicAuthenticator, Authenticatable {
    typealias User = App.User
    
    //Auth for API call
    static let shared = UserAuthenticator()
    let username = "teamit"
    let password = "surprizemi"
    
    func authenticate(basic: BasicAuthorization, for request: Request) -> EventLoopFuture<Void> {
        if basic.username == self.username && basic.password == self.password  {
            request.auth.login(User(name: "API user is trying to \(request.description)"))
        }
        return request.eventLoop.makeSucceededFuture(())
   }
}


struct UserPassForSaving: Authenticatable {
    
    let username = "teamit"
    let password = "surprizemi"
}


struct User: Authenticatable {
    var name: String
}
