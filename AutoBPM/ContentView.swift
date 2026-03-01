//
//  ContentView.swift
//  AutoBPM
//
//  Created by James Lok on 2026-02-28.
//

import SwiftUI

struct ContentView: View {
   var calculator: BPMCalculator
   @ObservedObject var rangeStore: BPMRangeStore
   @State private var statusMessage: String?
   @State private var isError = false
   @State private var showSettings = false
   @AppStorage("accentColorID") private var accentColorID = "blue"
   
   // Vibe tags
   @State private var availableTags: [String] = [
       "Chill", "Hype", "Groovy", "Dark", "Ethereal",
       "Uplifting", "Sad", "Aggressive", "Sexy", "Throwback"
   ]
   @State private var selectedTags: Set<String> = []
   @State private var customTagInput: String = ""
   @State private var vibeStatusMessage: String?
   @State private var isVibeError = false
   @State private var vibeExpanded = true
   @FocusState private var isTagFieldFocused: Bool
   @State private var trackInfo: TrackInfo?
   @State private var isPlaying = false
   
   private var roundedBPM: Int {
       Int(calculator.bpm.rounded())
   }
   
   var body: some View {
       Group {
           if showSettings {
               SettingsView(selectedColorID: $accentColorID, rangeStore: rangeStore) {
                   withAnimation { showSettings = false }
               }
           } else {
               mainView
           }
       }
       .tint(resolveAccentColor(for: accentColorID))
   }
   
   private var mainView: some View {
       VStack(spacing: 16) {
           // Header with settings gear
           HStack {
               Spacer()
               Button {
                   withAnimation { showSettings = true }
               } label: {
                   Image(systemName: "gearshape.fill")
                       .font(.caption)
                       .foregroundStyle(.secondary)
               }
               .buttonStyle(.borderless)
               .help("Settings")
           }
           
           // BPM Display
           Text(calculator.bpm > 0 ? "\(roundedBPM)" : "—")
               .font(.system(size: 64, weight: .bold, design: .rounded))
               .monospacedDigit()
               .contentTransition(.numericText())
               .animation(.snappy, value: roundedBPM)
           
           Text("BPM")
               .font(.title3)
               .foregroundStyle(.secondary)
           
           // Matched range for tapped BPM
           if roundedBPM > 0, let matched = rangeStore.matchingRange(for: roundedBPM) {
               Text(matched.name)
                   .font(.caption.weight(.semibold))
                   .padding(.horizontal, 8)
                   .padding(.vertical, 2)
                   .background(Color.accentColor.opacity(0.2))
                   .clipShape(Capsule())
           }
           
           // Tap count
           if calculator.tapCount > 0 {
               Text("\(calculator.tapCount) taps")
                   .font(.caption)
                   .foregroundStyle(.tertiary)
           }
           
           Divider()
           
           // Tap Button
           Button {
               calculator.tap()
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
               calculator.reset()
               statusMessage = nil
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
           DisclosureGroup("Apple Music", isExpanded: $vibeExpanded) {
           // Selected Track Info
           VStack(spacing: 4) {
               HStack {
                   Text("Selected Track")
                       .font(.caption.weight(.semibold))
                       .foregroundStyle(.secondary)
                   Spacer()
                   Button {
                       refreshTrackInfo()
                   } label: {
                       Image(systemName: "arrow.clockwise")
                           .font(.caption)
                   }
                   .buttonStyle(.borderless)
                   .help("Refresh track info")
               }
               
               if let trackInfo {
                   HStack(alignment: .center, spacing: 8) {
                       // Play/Pause button
                       Button {
                           togglePlayback()
                       } label: {
                           Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                               .font(.title2)
                               .foregroundStyle(.tint)
                       }
                       .buttonStyle(.borderless)
                       .help(isPlaying ? "Pause" : "Play")
                       
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
                           if trackInfo.bpm > 0, let matched = rangeStore.matchingRange(for: trackInfo.bpm) {
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
               setBPMToSelectedSong()
           } label: {
               Label("Set BPM to selected song", systemImage: "music.note")
                   .font(.body.weight(.semibold))
                   .frame(maxWidth: .infinity)
                   .padding(.vertical, 4)
           }
           .keyboardShortcut(.return, modifiers: [])
           .buttonStyle(.borderedProminent)
           .controlSize(.regular)
           .disabled(roundedBPM == 0)
           
           // BPM Status message
           if let statusMessage {
               Text(statusMessage)
                   .font(.caption)
                   .foregroundStyle(isError ? .red : .green)
                   .multilineTextAlignment(.center)
                   .transition(.opacity)
           }
           
           Divider()
           
           
               VStack(alignment: .leading, spacing: 8) {
                   // Tag chips - wrapping layout
                   FlowLayout(spacing: 6) {
                       ForEach(availableTags, id: \.self) { tag in
                           TagChip(
                               label: tag,
                               isSelected: selectedTags.contains(tag),
                               onTap: { toggleTag(tag) },
                               onRemove: isPresetTag(tag) ? nil : { removeTag(tag) }
                           )
                       }
                   }
                   
                   // Custom tag input
                   HStack(spacing: 6) {
                       TextField("Add tag…", text: $customTagInput)
                           .textFieldStyle(.roundedBorder)
                           .font(.caption)
                           .focused($isTagFieldFocused)
                           .onSubmit { addCustomTag() }
                       
                       Button {
                           addCustomTag()
                       } label: {
                           Image(systemName: "plus.circle.fill")
                       }
                       .buttonStyle(.borderless)
                       .disabled(customTagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                   }
                   
                   // Set Vibe / Reset buttons
                   HStack(spacing: 8) {
                       Button {
                           setVibeToSelectedSong()
                       } label: {
                           Label("Set vibe", systemImage: "waveform")
                               .font(.body.weight(.semibold))
                               .frame(maxWidth: .infinity)
                               .padding(.vertical, 4)
                       }
                       .buttonStyle(.borderedProminent)
                       .controlSize(.regular)
                       .disabled(selectedTags.isEmpty)
                       
                       Button {
                           resetVibe()
                       } label: {
                           Image(systemName: "arrow.counterclockwise")
                       }
                       .buttonStyle(.bordered)
                       .controlSize(.regular)
                       .disabled(selectedTags.isEmpty && vibeStatusMessage == nil)
                   }
                   
                   // Vibe status message
                   if let vibeStatusMessage {
                       Text(vibeStatusMessage)
                           .font(.caption)
                           .foregroundStyle(isVibeError ? .red : .green)
                           .multilineTextAlignment(.center)
                           .transition(.opacity)
                   }
               }
               .padding(.top, 4)
           }
           .font(.headline)
           
          
       }
       .padding(20)
       .frame(width: 260)
       .background {
           Color.clear
               .contentShape(Rectangle())
               .onTapGesture {
                   isTagFieldFocused = false
               }
       }
       .onAppear {
           refreshTrackInfo()
       }
       .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
           refreshTrackInfo()
       }
   }
   
   // MARK: - Preset tags
   
   private static let presetTags: Set<String> = [
       "Chill", "Hype", "Groovy", "Dark", "Melodic",
       "Uplifting", "Sad", "Aggressive", "Funky", "Dreamy"
   ]
   
   private func isPresetTag(_ tag: String) -> Bool {
       Self.presetTags.contains(tag)
   }
   
   // MARK: - Actions
   
   private func toggleTag(_ tag: String) {
       if selectedTags.contains(tag) {
           selectedTags.remove(tag)
       } else {
           selectedTags.insert(tag)
       }
   }
   
   private func addCustomTag() {
       let tag = customTagInput.trimmingCharacters(in: .whitespaces)
       guard !tag.isEmpty else { return }
       if !availableTags.contains(tag) {
           availableTags.append(tag)
       }
       selectedTags.insert(tag)
       customTagInput = ""
   }
   
   private func removeTag(_ tag: String) {
       availableTags.removeAll { $0 == tag }
       selectedTags.remove(tag)
   }
   
   private func setBPMToSelectedSong() {
       do {
           let result = try MusicService.setBPMToSelectedTrack(bpm: roundedBPM)
           withAnimation { statusMessage = result; isError = false }
           refreshTrackInfo()
       } catch {
           withAnimation { statusMessage = error.localizedDescription; isError = true }
       }
   }
   
    private func setVibeToSelectedSong() {
        let orderedTags = availableTags.filter { selectedTags.contains($0) }
        do {
            let result = try MusicService.setVibeToSelectedTrack(tags: orderedTags)
            withAnimation { vibeStatusMessage = result; isVibeError = false }
            refreshTrackInfo()
        } catch {
            withAnimation { vibeStatusMessage = error.localizedDescription; isVibeError = true }
        }
    }
    
    private func resetVibe() {
        withAnimation {
            selectedTags.removeAll()
            vibeStatusMessage = nil
        }
    }
    
    private func refreshTrackInfo() {
        do {
            trackInfo = try MusicService.getSelectedTrackInfo()
        } catch {
            trackInfo = nil
        }
        isPlaying = MusicService.isPlaying()
    }
    
    private func togglePlayback() {
        do {
            if isPlaying {
                try MusicService.pause()
            } else {
                try MusicService.playSelectedTrack()
            }
            isPlaying.toggle()
        } catch {
            // silently fail
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
