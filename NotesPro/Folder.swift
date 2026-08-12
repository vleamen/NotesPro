//
//  Folder.swift
//  NotesPro
//
//  Created by Vincent Nguyen on 8/12/26.
//

import Foundation
import SwiftData

@Model
class Folder {
    var id: UUID
    var name: String
    var creationDate: Date
    var isPinned: Bool = false
    
    // A folder can contain many notes. When a folder is deleted, cascade the deletion to all its notes.
    @Relationship(deleteRule: .cascade, inverse: \Note.folder)
    var notes: [Note]?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.creationDate = Date()
        self.notes = []
    }
}
