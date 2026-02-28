//
//  SettingsView.swift
//  AutoBPM
//
//  Created by James Lok on 2026-02-28.
//

import SwiftUI

struct AccentColorOption: Identifiable, Hashable {
    let id: String
    let name: String
    let color: Color
}

let accentColorOptions: [AccentColorOption] = [
    .init(id: "blue",    name: "Blue",    color: .blue),
    .init(id: "purple",  name: "Purple",  color: .purple),
    .init(id: "pink",    name: "Pink",    color: .pink),
    .init(id: "red",     name: "Red",     color: .red),
    .init(id: "orange",  name: "Orange",  color: .orange),
    .init(id: "yellow",  name: "Yellow",  color: .yellow),
    .init(id: "green",   name: "Green",   color: .green),
    .init(id: "mint",    name: "Mint",    color: .mint),
    .init(id: "teal",    name: "Teal",    color: .teal),
    .init(id: "cyan",    name: "Cyan",    color: .cyan),
    .init(id: "indigo",  name: "Indigo",  color: .indigo),
]

struct SettingsView: View {
    @Binding var selectedColorID: String
    @ObservedObject var rangeStore: BPMRangeStore
    var onDismiss: () -> Void
    
    @State private var newName = ""
    @State private var newMin = ""
    @State private var newMax = ""
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Text("Settings")
                    .font(.headline)
                
                Spacer()
                
                // Invisible spacer to balance the back button
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                    .hidden()
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Accent Color
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accent Color")
                            .font(.subheadline.weight(.medium))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                            ForEach(accentColorOptions) { option in
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 26, height: 26)
                                    .overlay {
                                        if selectedColorID == option.id {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedColorID = option.id
                                    }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // BPM Ranges
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Song Type Ranges")
                            .font(.subheadline.weight(.medium))
                        
                        // Existing ranges
                        ForEach($rangeStore.ranges) { $range in
                            BPMRangeRow(range: $range) {
                                withAnimation {
                                    rangeStore.ranges.removeAll { $0.id == range.id }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Add new range
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Add Range")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            TextField("Name (e.g. Sprint)", text: $newName)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                            
                            HStack(spacing: 6) {
                                TextField("Min BPM", text: $newMin)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                                
                                Text("–")
                                    .foregroundStyle(.secondary)
                                
                                TextField("Max BPM", text: $newMax)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                            }
                            
                            Button {
                                addRange()
                            } label: {
                                Label("Add", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 260, height: 420)
    }
    
    private func addRange() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let range = BPMRange(
            name: name,
            min: Int(newMin),
            max: Int(newMax)
        )
        withAnimation {
            rangeStore.ranges.append(range)
        }
        newName = ""
        newMin = ""
        newMax = ""
    }
}

// MARK: - BPM Range Row

struct BPMRangeRow: View {
    @Binding var range: BPMRange
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(range.name)
                .font(.caption.weight(.medium))
                .lineLimit(1)
            
            Spacer()
            
            Text(rangeLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
    
    private var rangeLabel: String {
        switch (range.min, range.max) {
        case let (lo?, hi?): return "\(lo)–\(hi) BPM"
        case let (lo?, nil): return "≥\(lo) BPM"
        case let (nil, hi?): return "≤\(hi) BPM"
        case (nil, nil):     return "No range"
        }
    }
}

func resolveAccentColor(for id: String) -> Color {
    accentColorOptions.first(where: { $0.id == id })?.color ?? .blue
}
