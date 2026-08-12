//
//  ContentView.swift
//  NotesPro
//
//  Created by Vincent Nguyen on 8/12/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // 1. Database environment and data fetching
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.creationDate) private var folders: [Folder]
    
    // 2. State management for navigation
    @State private var selectedFolder: Folder?
    @State private var selectedNote: Note?
    
    var body: some View {
        // 3. The Three-Pane Layout
        NavigationSplitView {
            // LEFT PANE: Folders
                        List(selection: $selectedFolder) {
                            ForEach(folders) { folder in
                                NavigationLink(value: folder) {
                                    Label(folder.name, systemImage: "folder")
                                }
                                // Right-Click Menu for Folders
                                .contextMenu {
                                    Button("Delete Folder", role: .destructive) {
                                        delete(folder: folder)
                                    }
                                }
                            }
                        }
                        .navigationTitle("Folders")
                        // Intercepts the hardware Delete key for the selected folder
                        .onDeleteCommand {
                            if let folder = selectedFolder {
                                delete(folder: folder)
                            }
                        }
                        .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 300)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button(action: addFolder) {
                                    Label("Add Folder", systemImage: "folder.badge.plus")
                                }
                            }
                        }
            
        } content: {
            // MIDDLE PANE: Notes List
                        if let folder = selectedFolder {
                            List(selection: $selectedNote) {
                                // Sort pinned notes to the top
                                let sortedNotes = (folder.notes ?? []).sorted {
                                    if $0.isPinned == $1.isPinned {
                                        return $0.lastEdited > $1.lastEdited
                                    }
                                    return $0.isPinned && !$1.isPinned
                                }
                                
                                ForEach(sortedNotes) { note in
                                    NavigationLink(value: note) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(note.title)
                                                    .font(.headline)
                                                Text(note.lastEdited, format: Date.FormatStyle(date: .numeric, time: .shortened))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            if note.isPinned {
                                                Image(systemName: "pin.fill")
                                                    .foregroundColor(.secondary)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                    // Right-Click Menu
                                    .contextMenu {
                                        Button(note.isPinned ? "Unpin Note" : "Pin Note") {
                                            note.isPinned.toggle()
                                        }
                                        Button("Duplicate") {
                                            duplicate(note: note, in: folder)
                                        }
                                        Divider()
                                        Button("Delete", role: .destructive) {
                                            delete(note: note)
                                        }
                                    }
                                }
                            }
                            .navigationTitle(folder.name)
                            // Intercepts the hardware Delete key for the selected list item
                            .onDeleteCommand {
                                if let note = selectedNote {
                                    delete(note: note)
                                }
                            }
                            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 400)
                            .toolbar {
                                ToolbarItem(placement: .primaryAction) {
                                    Button(action: addNote) {
                                        Label("Add Note", systemImage: "square.and.pencil")
                                    }
                                }
                            }
                        } else {
                            Text("Select a folder")
                                .foregroundColor(.secondary)
                        }
            
        } detail: {
            // RIGHT PANE: Note Editor
            if let note = selectedNote {
                NoteDetailView(note: note)
            } else {
                Text("Select a note to edit")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Database Actions
    
    private func addFolder() {
        let newFolder = Folder(name: "New Folder")
        modelContext.insert(newFolder)
        // Auto-select the new folder
        selectedFolder = newFolder
    }
    
    private func addNote() {
            guard let folder = selectedFolder else { return }
            // Removed the string argument, letting it default to empty Data
            let newNote = Note(title: "Untitled Note")
            
            folder.notes?.append(newNote)
            selectedNote = newNote
        }
    
    private func delete(note: Note) {
            modelContext.delete(note)
            if selectedNote == note {
                selectedNote = nil
            }
        }
    private func delete(folder: Folder) {
            // Tell the database to delete the folder (and all cascading notes)
            modelContext.delete(folder)
            
            // If the user deletes the folder they are currently viewing, clear both panes
            if selectedFolder == folder {
                selectedFolder = nil
                selectedNote = nil
            }
        }
        
        private func duplicate(note: Note, in folder: Folder) {
            // Creates a new record in the database just like cloning a row in SQLAlchemy
            let newNote = Note(title: note.title + " (Copy)", content: note.content)
            newNote.isPinned = note.isPinned
            folder.notes?.append(newNote)
        }
    
    private func deleteNotes(offsets: IndexSet) {
            // Ensure we have a folder and notes to work with
            guard let folder = selectedFolder, let notes = folder.notes else { return }
            
            for index in offsets {
                let noteToDelete = notes[index]
                // Tell the database to delete the record
                modelContext.delete(noteToDelete)
                
                // If the user deletes the note they are currently viewing, clear the right pane
                if selectedNote == noteToDelete {
                    selectedNote = nil
                }
            }
        }
}

// MARK: - Detail View Component

struct NoteDetailView: View {
    @Bindable var note: Note
    
    // The trigger that fires our NSViewRepresentable insertion logic
    @State private var insertTableTrigger = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Note Title", text: $note.title)
                .font(.system(size: 28, weight: .bold, design: .default))
                .textFieldStyle(.plain)
                .padding()
            
            Divider()
            
            // Replaced the basic TextEditor with our custom AppKit engine
            // Pass $note.content instead of text
                        RichTextEditor(contentData: $note.content, insertTableTrigger: $insertTableTrigger)
                            .padding()
        }
        .onChange(of: note.content) { _, _ in
            note.lastEdited = Date()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    insertTableTrigger = true
                }) {
                    Label("Insert Table", systemImage: "tablecells")
                }
            }
        }
    }
}
