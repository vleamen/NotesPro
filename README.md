# Notes Pro

A macOS application prototype that explores the integration of rich text processing, interactive inline components, and local data persistence using modern Apple frameworks.

This project recreates the core document-driven layout of Apple Notes, but extends it by embedding a fully interactive, formula-capable spreadsheet engine directly into the text flow.

## Architecture & Frameworks

* **TextKit 2 & AppKit:** Uses `NSTextView` wrapped in an `NSViewRepresentable` to handle rich text rendering, custom layouts, and hardware event delegation.
* **Inline SwiftUI Embeds:** Utilizes `NSTextAttachmentViewProvider` to inject declarative SwiftUI views (the spreadsheet grid) directly into the `NSAttributedString` document flow. 
* **Data Persistence:** Implements **SwiftData** with cascading deletion rules to manage a relational schema between Folders and Notes. Document content is serialized and archived as binary `Data` to preserve rich text attributes and attachments across sessions.
* **Reactive Math Engine:** A custom-built parser and evaluation engine (`ObservableObject`) that processes standard spreadsheet formulas (e.g., `=SUM(A1:A3)`) independently of the surrounding text view.

## Features

* Three-pane native macOS layout (`NavigationSplitView`) with sidebar context menus.
* Persistent, relational folder and note management.
* Hardware keyboard event interception (e.g., native Delete key support in lists).
* Inline table insertion at cursor position with accurate text-wrapping bounds.
* Minimalist, system-native UI utilizing macOS environment variables (`NSColor.gridColor`, `tertiaryLabelColor`).

*Supported Formulas & Operations
=SUM(range)

Calculates the total sum of all numerical values within a specified cell range (e.g., =SUM(A1:A3)).

=AVG(range)

Computes the average (mean) of all numerical values within a specified range (e.g., =AVG(B1:B5)).

=MIN(range)

Evaluates a given range and returns the lowest numerical value.

=MAX(range)

Evaluates a given range and returns the highest numerical value.

=COUNT(range)

Returns the total number of cells containing numerical data within a specified range.

Basic Arithmetic Operators

Supports standard mathematical operations between specific cells or static numbers using +, -, *, and / (e.g., =A1*B1 or =C2/4).

## Download & Install

You can download the compiled app directly without needing to build it in Xcode.

1. Go to the [Releases](../../releases) page and download `NotesPro.zip`.
2. Unzip the file and drag `NotesPro.app` into your **Applications** folder.
3. **Important Note:** Because this is an unsigned portfolio project, macOS will block it from opening the first time. To open it:
   * **Right-click** (or Control-click) `NotesPro.app` in your Applications folder.
   * Select **Open** from the menu.
   * Click **Open** again on the security prompt. (You only have to do this once).
