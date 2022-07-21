import Fluent
import Vapor
import SWXMLHash

func routes(_ app: Application) throws {
    

    
    app.get { req in
        
        return "It works!"
    }
    
    app.get("hello") { req -> String in
       
        
        return "Hello srki"
    }
    
    app.get("try" ) { req -> String in
        return "Hello"
        
    }
    
    
    
    try app.register(collection: RiverController())
    
    

    

}




