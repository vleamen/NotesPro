//
//  SpreadsheetView.swift
//  NotesPro
//
//  Created by Vincent Nguyen on 8/12/26.
//

import SwiftUI
import Combine // Fixes the ObservableObject / missing import errors

// MARK: - Data Model

struct CellData: Identifiable {
    let id = UUID()
    var rawInput: String = ""
    var displayValue: String = ""
}

// MARK: - The Spreadsheet Engine

// MARK: - The Spreadsheet Engine

class SpreadsheetEngine: ObservableObject {
    let rows: Int = 8
    let cols: Int = 4
    
    @Published var grid: [[CellData]]
    
    init() {
        var initialGrid: [[CellData]] = []
        for _ in 0..<rows {
            var row: [CellData] = []
            for _ in 0..<cols {
                row.append(CellData())
            }
            initialGrid.append(row)
        }
        self.grid = initialGrid
    }
    
    func evaluateAll() {
        for r in 0..<rows {
            for c in 0..<cols {
                grid[r][c].displayValue = evaluate(input: grid[r][c].rawInput)
            }
        }
    }
    
    private func evaluate(input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("=") else { return trimmed }
        
        let formula = trimmed.dropFirst().uppercased()
        
        // 1. Aggregate Functions
        if formula.hasPrefix("SUM(") && formula.hasSuffix(")") {
            let rangeString = String(formula.dropFirst(4).dropLast())
            let numbers = getNumbers(from: rangeString)
            return formatResult(numbers.reduce(0, +))
        }
        
        if formula.hasPrefix("AVG(") && formula.hasSuffix(")") {
            let rangeString = String(formula.dropFirst(4).dropLast())
            let numbers = getNumbers(from: rangeString)
            guard !numbers.isEmpty else { return "0" }
            return formatResult(numbers.reduce(0, +) / Double(numbers.count))
        }
        
        if formula.hasPrefix("COUNT(") && formula.hasSuffix(")") {
            let rangeString = String(formula.dropFirst(6).dropLast())
            let numbers = getNumbers(from: rangeString)
            return "\(numbers.count)"
        }
        
        if formula.hasPrefix("MIN(") && formula.hasSuffix(")") {
            let rangeString = String(formula.dropFirst(4).dropLast())
            let numbers = getNumbers(from: rangeString)
            guard !numbers.isEmpty else { return "0" }
            return formatResult(numbers.min()!)
        }
        
        if formula.hasPrefix("MAX(") && formula.hasSuffix(")") {
            let rangeString = String(formula.dropFirst(4).dropLast())
            let numbers = getNumbers(from: rangeString)
            guard !numbers.isEmpty else { return "0" }
            return formatResult(numbers.max()!)
        }
        
        // 2. Basic Arithmetic Fallback (e.g., A1+B2 or C3*4)
        if let mathResult = evaluateBasicMath(formula) {
            return mathResult
        }
        
        return "#ERROR"
    }
    
    // MARK: - Helper Methods
    
    private func evaluateBasicMath(_ expression: String) -> String? {
        let operators: [Character] = ["+", "-", "*", "/"]
        
        // Find the first operator to split the expression
        guard let op = expression.first(where: { operators.contains($0) }) else { return nil }
        
        let parts = expression.split(separator: op)
        guard parts.count == 2 else { return nil }
        
        let lhs = resolveValue(String(parts[0]).trimmingCharacters(in: .whitespaces))
        let rhs = resolveValue(String(parts[1]).trimmingCharacters(in: .whitespaces))
        
        switch op {
        case "+": return formatResult(lhs + rhs)
        case "-": return formatResult(lhs - rhs)
        case "*": return formatResult(lhs * rhs)
        case "/": return rhs == 0 ? "#DIV/0!" : formatResult(lhs / rhs)
        default: return nil
        }
    }
    
    private func resolveValue(_ string: String) -> Double {
        // If it's just a static number, return it
        if let num = Double(string) { return num }
        
        // Otherwise, see if it's a valid cell reference (e.g., "A1")
        if let (row, col) = parseAddress(string), row < rows, col < cols {
            return Double(grid[row][col].displayValue) ?? 0.0
        }
        
        return 0.0
    }
    
    private func getNumbers(from range: String) -> [Double] {
        let parts = range.components(separatedBy: ":")
        guard parts.count == 2 else { return [] }
        
        let startRef = parts[0]
        let endRef = parts[1]
        
        guard let start = parseAddress(startRef), let end = parseAddress(endRef) else { return [] }
        
        var numbers: [Double] = []
        
        for r in min(start.row, end.row)...max(start.row, end.row) {
            for c in min(start.col, end.col)...max(start.col, end.col) {
                if r < rows && c < cols {
                    let cellVal = grid[r][c].displayValue
                    if let num = Double(cellVal) {
                        numbers.append(num)
                    }
                }
            }
        }
        return numbers
    }
    
    private func parseAddress(_ address: String) -> (row: Int, col: Int)? {
        guard address.count >= 2 else { return nil }
        
        let colChar = address.first!.uppercased()
        let colIndex = Int(colChar.unicodeScalars.first!.value) - 65
        
        let rowString = String(address.dropFirst())
        guard let rowNum = Int(rowString) else { return nil }
        let rowIndex = rowNum - 1
        
        return (row: rowIndex, col: colIndex)
    }
    
    private func formatResult(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - The UI

// MARK: - The UI

struct CellIndex: Hashable {
    let row: Int
    let col: Int
}

struct SpreadsheetView: View {
    @StateObject private var engine = SpreadsheetEngine()
    @FocusState private var focusedCell: CellIndex?
    
    let headers = ["A", "B", "C", "D"]
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                
                // 1. Header Row (Styled like Notes selection handles)
                GridRow {
                    Color.clear.frame(width: 24, height: 20)
                    
                    ForEach(headers, id: \.self) { header in
                        Text(header)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(NSColor.tertiaryLabelColor))
                            .frame(width: 100, height: 20)
                            .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
                            .border(Color(NSColor.gridColor), width: 0.5)
                    }
                }
                
                // 2. Data Rows
                ForEach(0..<engine.rows, id: \.self) { row in
                    GridRow {
                        // Row Number Header
                        Text("\(row + 1)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(NSColor.tertiaryLabelColor))
                            .frame(width: 24, height: 32)
                            .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
                            .border(Color(NSColor.gridColor), width: 0.5)
                        
                        // Data Cells
                        ForEach(0..<engine.cols, id: \.self) { col in
                            SpreadsheetCellView(
                                cellData: $engine.grid[row][col],
                                index: CellIndex(row: row, col: col),
                                isFocused: focusedCell == CellIndex(row: row, col: col),
                                focusedCell: $focusedCell
                            )
                        }
                    }
                }
            }
        }
        // Removed the rounded corners and shadow to make it flush with the text flow
        .padding(.vertical, 8)
        .onChange(of: focusedCell) { oldVal, newVal in
            if newVal == nil || oldVal != nil {
                engine.evaluateAll()
            }
        }
    }
}

// MARK: - Extracted Subview for Clean Cells

// MARK: - Extracted Subview for Clean Cells

struct SpreadsheetCellView: View {
    @Binding var cellData: CellData
    let index: CellIndex
    let isFocused: Bool
    var focusedCell: FocusState<CellIndex?>.Binding
    
    var body: some View {
        ZStack(alignment: .leading) {
            // The active text field when typing/editing formula
            TextField("", text: $cellData.rawInput)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(.horizontal, 8)
                .autocorrectionDisabled() // Updated for macOS
            
            // The evaluated display value overlay when not focused
            if !isFocused && !cellData.displayValue.isEmpty {
                Text(cellData.displayValue)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .background(Color(NSColor.textBackgroundColor))
                    .allowsHitTesting(false)
            }
        }
        .frame(width: 100, height: 32)
        .background(Color(NSColor.textBackgroundColor))
        .border(Color(NSColor.gridColor), width: 0.5)
        .overlay(
            Rectangle()
                .stroke(isFocused ? Color.accentColor : Color.clear, lineWidth: isFocused ? 2 : 0)
        )
        .focused(focusedCell, equals: index)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    }
}
