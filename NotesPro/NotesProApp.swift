//
//  NotesProApp.swift
//  NotesPro
//
//  Created by Vincent Nguyen on 8/12/26.
//

import SwiftUI
import SwiftData

@main
struct NotesProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // This is all you need to initialize the local database
        .modelContainer(for: [Folder.self, Note.self])
    }
}
