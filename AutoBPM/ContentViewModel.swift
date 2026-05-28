//
//  ContentViewModel.swift
//  AutoBPM
//
//  Created by James Lok on 2026-05-28.
//

import SwiftUI
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    let calculator: BPMCalculator
    let rangeStore: BPMRangeStore

    @Published var statusMessage: String?
    @Published var isError = false
    @Published var showSettings = false
    @Published var availableTags: [String] = [
        "Chill", "Hype", "Groovy", "Dark", "Ethereal",
        "Uplifting", "Sad", "Aggressive", "Sexy", "Throwback"
    ]
    @Published var selectedTags: Set<String> = []
    @Published var customTagInput: String = ""
    @Published var vibeStatusMessage: String?
    @Published var isVibeError = false
    @Published var vibeExpanded = true
    @Published var trackInfo: TrackInfo?
    @Published var isPlaying = false

    private static let presetTags: Set<String> = [
        "Chill", "Hype", "Groovy", "Dark", "Melodic",
        "Uplifting", "Sad", "Aggressive", "Funky", "Dreamy"
    ]

    var roundedBPM: Int {
        Int(calculator.bpm.rounded())
    }

    init(calculator: BPMCalculator, rangeStore: BPMRangeStore) {
        self.calculator = calculator
        self.rangeStore = rangeStore
    }

    func isPresetTag(_ tag: String) -> Bool {
        Self.presetTags.contains(tag)
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    func addCustomTag() {
        let tag = customTagInput.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty else { return }
        if !availableTags.contains(tag) {
            availableTags.append(tag)
        }
        selectedTags.insert(tag)
        customTagInput = ""
    }

    func removeTag(_ tag: String) {
        availableTags.removeAll { $0 == tag }
        selectedTags.remove(tag)
    }

    func tap() {
        calculator.tap()
    }

    func reset() {
        calculator.reset()
        statusMessage = nil
    }

    func setBPMToSelectedSong() {
        let prepend = UserDefaults.standard.object(forKey: "prependBPMToTitle") as? Bool ?? true
        do {
            let result = try MusicService.setBPMToSelectedTrack(bpm: roundedBPM, prependToTitle: prepend)
            withAnimation { statusMessage = result; isError = false }
            refreshTrackInfo()
        } catch {
            withAnimation { statusMessage = error.localizedDescription; isError = true }
        }
    }

    func setVibeToSelectedSong() {
        let orderedTags = availableTags.filter { selectedTags.contains($0) }
        do {
            let result = try MusicService.setVibeToSelectedTrack(tags: orderedTags)
            withAnimation { vibeStatusMessage = result; isVibeError = false }
            refreshTrackInfo()
        } catch {
            withAnimation { vibeStatusMessage = error.localizedDescription; isVibeError = true }
        }
    }

    func resetVibe() {
        withAnimation {
            selectedTags.removeAll()
            vibeStatusMessage = nil
        }
    }

    func refreshTrackInfo() {
        do {
            trackInfo = try MusicService.getSelectedTrackInfo()
        } catch {
            trackInfo = nil
        }
        isPlaying = MusicService.isPlaying()
    }

    func togglePlayback() {
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
