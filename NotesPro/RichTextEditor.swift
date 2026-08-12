//
//  RichTextEditor.swift
//  NotesPro
//
//  Created by Vincent Nguyen on 8/12/26.
//

import SwiftUI
import AppKit

// MARK: - The SwiftUI AppKit Wrapper
struct RichTextEditor: NSViewRepresentable {
    @Binding var contentData: Data
    @Binding var insertTableTrigger: Bool
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        
        // Explicitly enabling TextKit 2 is REQUIRED for SwiftUI view attachments
        let textView = NSTextView(usingTextLayoutManager: true)
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        
        textView.delegate = context.coordinator
        textView.allowsUndo = true
        textView.isRichText = true
        textView.importsGraphics = true
        textView.font = NSFont.systemFont(ofSize: 14)
        
        scrollView.documentView = textView
        
        // Register the custom SwiftUI View Provider
        NSTextAttachment.registerViewProviderClass(SpreadsheetViewProvider.self, forFileType: "public.data")
        
        // Load the initial rich text from the database
        if !contentData.isEmpty,
           let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: contentData) {
            textView.textStorage?.setAttributedString(unarchived)
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
            guard let textView = nsView.documentView as? NSTextView else { return }
            
            if insertTableTrigger {
                DispatchQueue.main.async {
                    insertTableTrigger = false
                    
                    let attachment = NSTextAttachment(data: Data(), ofType: "public.data")
                    
                    // THE FIX: We must explicitly tell the text engine how much physical space
                    // to carve out for the SwiftUI view inside the paragraph flow.
                    attachment.bounds = NSRect(x: 0, y: 0, width: 450, height: 300)
                    
                    let attachmentString = NSAttributedString(attachment: attachment)
                    
                    // Get the cursor location and insert the table
                    let cursorLocation = textView.selectedRange().location
                    textView.textStorage?.insert(attachmentString, at: cursorLocation)
                    
                    // Force the text to redraw around the new 450x300 cutout
                    textView.didChangeText()
                }
            }
        }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        init(_ parent: RichTextEditor) { self.parent = parent }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Compress the rich text and attachments into a Data blob for SwiftData
            if let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: textView.attributedString(), requiringSecureCoding: false) {
                parent.contentData = archivedData
            }
        }
    }
}

// MARK: - The SwiftUI to TextKit Bridge
class SpreadsheetViewProvider: NSTextAttachmentViewProvider {
    override func loadView() {
        let hostingView = NSHostingView(rootView: SpreadsheetView())
        hostingView.frame = NSRect(x: 0, y: 0, width: 450, height: 300)
        self.view = hostingView
    }
}
