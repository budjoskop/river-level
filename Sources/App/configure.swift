import Fluent
import FluentPostgresDriver
import Vapor
import VaporCron

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .psql)


    
    if let databaseURL = Environment.get("DATABASE_URL"), var postgresConfig = PostgresConfiguration(url: databaseURL) {
        postgresConfig.tlsConfiguration = .makeClientConfiguration()
        postgresConfig.tlsConfiguration?.certificateVerification = .none
        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    } else {
        // ...
        print("nesto se desava satro")
    }
    
    app.migrations.add(CreateRiver())
    
    try app.autoMigrate().wait() // comment this latter, this is doing all the updates in DB
    
    try app.cron.schedule(SaveRiversInDB.self)
    
    // register routes
    try routes(app)
}



struct SaveRiversInDB: VaporCronSchedulable {
    static var expression: String { "* 13 * * *" }
    static let dateFormater = DateFormatter()
    static let river = RiverController()
    
    static func task(on application: Application) -> EventLoopFuture<RiverPresentation> { 
        application.logger.info("🧭 CRON JOB save xml started 🧭")
        let dateString = dateFormater.string(from: Date())
        let date = dateFormater.date(from: dateString)
        let riverName = RiverPresentation(id: nil, river: [River](), dateCreation: date!)
       
        print("🎯 POST request to save in DB init 🎯")
//        print(try req.auth.require(User.self).name)
        dateFormater.dateFormat = "MM-dd-yyyy HH:mm"
        
        
        
        riverName.river = river.fetchXml()
        let req = Request(application: application, on: application.db.eventLoop)
        application.logger.info("✅ CRON JOB save xml success ✅")
        return riverName.save(on: req.db).map {
            riverName
        }
    }
}
