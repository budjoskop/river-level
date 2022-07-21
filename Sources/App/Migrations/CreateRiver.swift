import Fluent


struct CreateRiver: Migration {
    
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("levels")
            .id()
            .field("rivers", .array(of: .json), .required)
            .field("dateCreation", .date, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("levels").delete()
    }
    
}

