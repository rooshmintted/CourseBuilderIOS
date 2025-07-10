//
//  CourseBuilderApp.swift
//  CourseBuilder
//
//  Created by Roosh on 7/10/25.
//

import SwiftUI

@main
struct CourseBuilderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
