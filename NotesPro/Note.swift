//
//  Note.swift
//  NotesPro
//
//  Created by Vincent Nguyen on 8/12/26.
//

import Foundation
import SwiftData

@Model
class Note {
    var id: UUID
    var title: String
    var content: Data
    var lastEdited: Date
    var isPinned: Bool = false // Restored!
    
    var folder: Folder?
    
    init(title: String = "New Note", content: Data = Data()) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.lastEdited = Date()
    }
}
