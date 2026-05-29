//
//  ContentView.swift
//  AutoBPM
//
//  Created by James Lok on 2026-02-28.
//

import SwiftUI

struct ContentView: View {
   @StateObject private var viewModel: ContentViewModel
   @ObservedObject private var trackMonitor = MusicTrackMonitor.shared
   @AppStorage("showVibeFeature") private var showVibeFeature = true
   @FocusState private var isTagFieldFocused: Bool

   init(calculator: BPMCalculator, rangeStore: BPMRangeStore) {
       _viewModel = StateObject(wrappedValue: ContentViewModel(calculator: calculator, rangeStore: rangeStore))
   }
   
   var body: some View {
       Group {
           if viewModel.showSettings {
               SettingsView(rangeStore: viewModel.rangeStore) {
                   withAnimation { viewModel.showSettings = false }
               }
           } else {
               mainView
           }
       }
       .tint(Color.accentColor)
   }
   
   private var mainView: some View {
       VStack(spacing: 16) {
           // Header with settings gear
           HStack {
               Spacer()
               Button {
                   withAnimation { viewModel.showSettings = true }
               } label: {
                   Image(systemName: "gearshape.fill")
                       .font(.caption)
                       .foregroundStyle(.white)
               }
               .buttonStyle(.borderless)
               .help("Settings")
           }
           
           // BPM Display
           Text(viewModel.calculator.bpm > 0 ? "\(viewModel.roundedBPM)" : "—")
               .font(.system(size: 64, weight: .bold, design: .rounded))
               .monospacedDigit()
               .contentTransition(.numericText())
               .animation(.snappy, value: viewModel.roundedBPM)
               .onTapGesture(count: 2) {
                   guard viewModel.roundedBPM > 0 else { return }
                   NSPasteboard.general.clearContents()
                   NSPasteboard.general.setString("\(viewModel.roundedBPM)", forType: .string)
                   withAnimation { viewModel.statusMessage = "Copied \(viewModel.roundedBPM) BPM to clipboard"; viewModel.isError = false }
               }
           
           Text("BPM")
               .font(.title3)
               .foregroundStyle(.secondary)
           
           // Matched range for tapped BPM
           if viewModel.roundedBPM > 0, let matched = viewModel.rangeStore.matchingRange(for: viewModel.roundedBPM) {
               Text(matched.name)
                   .font(.caption.weight(.semibold))
                   .padding(.horizontal, 8)
                   .padding(.vertical, 2)
                   .background(Color.accentColor.opacity(0.2))
                   .clipShape(Capsule())
           }
           
           // Tap count
           if viewModel.calculator.tapCount > 0 {
               Text("\(viewModel.calculator.tapCount) taps")
                   .font(.caption)
                   .foregroundStyle(.tertiary)
           }
           
           Divider()
           
           // Tap Button
           Button {
               viewModel.tap()
           } label: {
               Text("Tap")
                   .font(.title2.weight(.semibold))
                   .frame(maxWidth: .infinity)
                   .padding(.vertical, 8)
           }
           .keyboardShortcut(.space, modifiers: [])
           .buttonStyle(.borderedProminent)
           .controlSize(.large)
           
           // Reset Button
           Button {
               viewModel.reset()
           } label: {
               Text("Reset")
                   .frame(maxWidth: .infinity)
           }
           .keyboardShortcut(.delete, modifiers: [])
           .buttonStyle(.bordered)
           .controlSize(.regular)
           
           Text("Press **Space** to tap, **Return** to set BPM, **Delete** to reset")
               .font(.caption2)
               .foregroundStyle(.quaternary)
           
           Divider()
           DisclosureGroup("Apple Music", isExpanded: $viewModel.vibeExpanded) {
           // Selected Track Info
           VStack(spacing: 4) {
               HStack {
                   Text("Selected Track")
                       .font(.caption.weight(.semibold))
                       .foregroundStyle(.secondary)
                   Spacer()
                   Button {
                       viewModel.refreshTrackInfo()
                   } label: {
                       Image(systemName: "arrow.clockwise")
                           .font(.caption)
                   }
                   .buttonStyle(.borderless)
                   .help("Refresh track info")
               }
               
               if let trackInfo = viewModel.trackInfo {
                   HStack(alignment: .center, spacing: 8) {
                       // Play/Pause button
                       Button {
                           viewModel.togglePlayback()
                       } label: {
                           Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                               .font(.title2)
                               .foregroundStyle(.tint)
                       }
                       .buttonStyle(.borderless)
                       .help(viewModel.isPlaying ? "Pause" : "Play")
                       
                       VStack(alignment: .leading, spacing: 2) {
                           Text(trackInfo.name)
                               .font(.caption.weight(.medium))
                               .lineLimit(1)
                               .truncationMode(.tail)
                               .frame(maxWidth: .infinity, alignment: .leading)
                           
                           Text(trackInfo.artist)
                               .font(.caption2)
                               .foregroundStyle(.secondary)
                               .lineLimit(1)
                               .truncationMode(.tail)
                               .frame(maxWidth: .infinity, alignment: .leading)
                           
                           HStack(spacing: 8) {
                               Label(
                                   trackInfo.bpm > 0 ? "\(trackInfo.bpm) BPM" : "No BPM",
                                   systemImage: "metronome"
                               )
                               .font(.caption2)
                               .foregroundStyle(trackInfo.bpm > 0 ? .primary : .tertiary)
                               
                               if !trackInfo.grouping.isEmpty {
                                   Label(trackInfo.grouping, systemImage: "tag")
                                       .font(.caption2)
                                       .foregroundStyle(.secondary)
                                       .lineLimit(1)
                                       .truncationMode(.tail)
                               }
                           }
                           
                           // Matched song type range
                           if trackInfo.bpm > 0, let matched = viewModel.rangeStore.matchingRange(for: trackInfo.bpm) {
                               Text(matched.name)
                                   .font(.caption2.weight(.semibold))
                                   .padding(.horizontal, 6)
                                   .padding(.vertical, 2)
                                   .background(Color.accentColor.opacity(0.2))
                                   .clipShape(Capsule())
                           }
                       }
                   }
                   .padding(8)
                   .frame(maxWidth: .infinity)
                   .background(Color.secondary.opacity(0.08))
                   .clipShape(RoundedRectangle(cornerRadius: 6))
               } else {
                   Text("No track selected")
                       .font(.caption)
                       .foregroundStyle(.tertiary)
                       .frame(maxWidth: .infinity)
                       .padding(8)
               }
           }
           
           // Set BPM to Apple Music
           Button {
               viewModel.setBPMToSelectedSong()
           } label: {
               Label("Set BPM to song", systemImage: "music.note")
                   .font(.body.weight(.semibold))
                   .frame(maxWidth: .infinity)
                   .padding(.vertical, 4)
           }
           .keyboardShortcut(.return, modifiers: [])
           .buttonStyle(.borderedProminent)
           .controlSize(.regular)
           .disabled(viewModel.roundedBPM == 0)
           
           // BPM Status message
           if let statusMessage = viewModel.statusMessage {
               Text(statusMessage)
                   .font(.caption)
                   .foregroundStyle(viewModel.isError ? .red : .green)
                   .multilineTextAlignment(.center)
                   .transition(.opacity)
           }
           
           Divider()
           
               if showVibeFeature {
                   VStack(alignment: .leading, spacing: 8) {
                       // Tag chips - wrapping layout
                       FlowLayout(spacing: 6) {
                           ForEach(viewModel.availableTags, id: \.self) { tag in
                               TagChip(
                                label: tag,
                                isSelected: viewModel.selectedTags.contains(tag),
                                onTap: { viewModel.toggleTag(tag) },
                                onRemove: viewModel.isPresetTag(tag) ? nil : { viewModel.removeTag(tag) }
                               )
                           }
                       }
                       
                       // Custom tag input
                       HStack(spacing: 6) {
                           TextField("Add tag…", text: $viewModel.customTagInput)
                               .textFieldStyle(.roundedBorder)
                               .font(.caption)
                               .focused($isTagFieldFocused)
                               .onSubmit { viewModel.addCustomTag() }
                           
                           Button {
                               viewModel.addCustomTag()
                           } label: {
                               Image(systemName: "plus.circle.fill")
                           }
                           .buttonStyle(.borderless)
                           .disabled(viewModel.customTagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                       }
                       
                       // Set Vibe / Reset buttons
                       HStack(spacing: 8) {
                           Button {
                               viewModel.setVibeToSelectedSong()
                           } label: {
                               Label("Set vibe", systemImage: "waveform")
                                   .font(.body.weight(.semibold))
                                   .frame(maxWidth: .infinity)
                                   .padding(.vertical, 4)
                           }
                           .buttonStyle(.borderedProminent)
                           .controlSize(.regular)
                           .disabled(viewModel.selectedTags.isEmpty)
                           
                           Button {
                               viewModel.resetVibe()
                           } label: {
                               Image(systemName: "arrow.counterclockwise")
                           }
                           .buttonStyle(.bordered)
                           .controlSize(.regular)
                           .disabled(viewModel.selectedTags.isEmpty && viewModel.vibeStatusMessage == nil)
                       }
                       
                       // Vibe status message
                       if let vibeStatusMessage = viewModel.vibeStatusMessage {
                           Text(vibeStatusMessage)
                               .font(.caption)
                               .foregroundStyle(viewModel.isVibeError ? .red : .green)
                               .multilineTextAlignment(.center)
                               .transition(.opacity)
                       }
                   }
                   .padding(.top, 4)
               }
           }
           .font(.headline)
       }
       .padding(20)
       .frame(width: 260)
       .contextMenu {
           Button("Quit") {
               NSApplication.shared.terminate(nil)
           }
           .keyboardShortcut("q")
       }
       .background {
           Color.clear
               .contentShape(Rectangle())
               .onTapGesture {
                   isTagFieldFocused = false
               }
       }
       .onAppear {
           viewModel.refreshTrackInfo()
       }
       .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
           viewModel.refreshTrackInfo()
       }
       .onReceive(NotificationCenter.default.publisher(for: .musicTrackDidChange)) { _ in
           viewModel.refreshTrackInfo()
       }
   }
}

// MARK: - Tag Chip View

struct TagChip: View {
   let label: String
   let isSelected: Bool
   let onTap: () -> Void
   var onRemove: (() -> Void)?
   
   var body: some View {
       HStack(spacing: 4) {
           Text(label)
               .font(.caption)
           
           if let onRemove {
               Button {
                   onRemove()
               } label: {
                   Image(systemName: "xmark.circle.fill")
                       .font(.caption2)
                       .foregroundStyle(.secondary)
               }
               .buttonStyle(.plain)
           }
       }
       .padding(.horizontal, 8)
       .padding(.vertical, 4)
       .background(isSelected ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.12))
       .foregroundStyle(isSelected ? .primary : .secondary)
       .clipShape(Capsule())
       .overlay(Capsule().stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1))
       .onTapGesture { onTap() }
   }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
   var spacing: CGFloat = 6
   
   func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
       let result = layout(proposal: proposal, subviews: subviews)
       return result.size
   }
   
   func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
       let result = layout(proposal: proposal, subviews: subviews)
       for (index, position) in result.positions.enumerated() {
           subviews[index].place(
               at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
               proposal: .unspecified
           )
       }
   }
   
   private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
       let maxWidth = proposal.width ?? .infinity
       var positions: [CGPoint] = []
       var x: CGFloat = 0
       var y: CGFloat = 0
       var rowHeight: CGFloat = 0
       var totalWidth: CGFloat = 0
       
       for subview in subviews {
           let size = subview.sizeThatFits(.unspecified)
           if x + size.width > maxWidth, x > 0 {
               x = 0
               y += rowHeight + spacing
               rowHeight = 0
           }
           positions.append(CGPoint(x: x, y: y))
           rowHeight = max(rowHeight, size.height)
           x += size.width + spacing
           totalWidth = max(totalWidth, x - spacing)
       }
       
       return (CGSize(width: totalWidth, height: y + rowHeight), positions)
   }
}

#Preview {
   ContentView(calculator: BPMCalculator(), rangeStore: BPMRangeStore())
}
