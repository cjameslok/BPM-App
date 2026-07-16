//
//  MusicService.swift
//  AutoBPM
//
//  Created by James Lok on 2026-02-28.
//

import Foundation
import AppKit
import Combine

enum MusicServiceError: LocalizedError {
    case noTrackSelected
    case scriptError(String)
    case noBPM
    case noVibe

    var errorDescription: String? {
        switch self {
        case .noTrackSelected:
            return "No track is selected in Apple Music."
        case .scriptError(let message):
            return "AppleScript error: \(message)"
        case .noBPM:
            return "No BPM value to set. Tap a tempo first."
        case .noVibe:
            return "No vibe tags selected."
        }
    }
}

struct TrackInfo {
    let name: String
    let artist: String
    let bpm: Int
    let grouping: String
}

struct MusicService {

    /// Reads info from the currently playing Apple Music track.
    static func getSelectedTrackInfo() throws -> TrackInfo {
        let script = """
        tell application "Music"
            if player state is playing then
                set t to current track
                set trackName to name of t
                set trackArtist to artist of t
                set trackBPM to bpm of t
                set trackGrouping to grouping of t
                return trackName & "||" & trackArtist & "||" & (trackBPM as text) & "||" & trackGrouping
            else
                error "Nothing is playing"
            end if
        end tell
        """
        let result = try runAppleScript(script)
        let parts = result.components(separatedBy: "||")
        
        return TrackInfo(
            name: parts.count > 0 ? parts[0] : "",
            artist: parts.count > 1 ? parts[1] : "",
            bpm: parts.count > 2 ? (Int(parts[2]) ?? 0) : 0,
            grouping: parts.count > 3 ? parts[3] : ""
        )
    }

    /// Sets the BPM on the currently playing Apple Music track and prepends it to the song title.
    /// - Parameter bpm: The BPM value to set.
    /// - Returns: A description string like "Set 120 BPM → Song Name"
    @discardableResult
    static func setBPMToSelectedTrack(bpm: Int, prependToTitle: Bool = true) throws -> String {
        guard bpm > 0 else { throw MusicServiceError.noBPM }

        // 1. Get the current track name
        let getName = """
        tell application "Music"
            if player state is playing then
                set t to current track
                return name of t
            else
                error "Nothing is playing"
            end if
        end tell
        """
        let currentName = try runAppleScript(getName)

        // 2. Build the new name: strip any existing leading BPM prefix ("123 - ")
        let stripped = stripExistingBPMPrefix(from: currentName)
        let newName = prependToTitle ? "\(bpm) - \(stripped)" : stripped

        // 3. Set BPM and name on the currently playing track
        let escapedName = newName.replacingOccurrences(of: "\\", with: "\\\\")
                                 .replacingOccurrences(of: "\"", with: "\\\"")
        let setScript = """
        tell application "Music"
            set t to current track
            set bpm of t to \(bpm)
            set name of t to "\(escapedName)"
        end tell
        """
        try runAppleScript(setScript)

        return "Set \(bpm) BPM → \(newName)"
    }

    /// Appends comma-separated vibe tags to the grouping field on the currently playing Apple Music track,
    /// preserving any existing text and skipping tags already present.
    /// - Parameter tags: The vibe tags to write.
    /// - Returns: A description string like "Set vibes → Chill, Groovy"
    @discardableResult
    static func setVibeToSelectedTrack(tags: [String]) throws -> String {
        guard !tags.isEmpty else { throw MusicServiceError.noVibe }

        // Read the existing grouping so new tags are appended rather than overwriting
        let getGrouping = """
        tell application "Music"
            if player state is playing then
                return grouping of current track
            else
                error "Nothing is playing"
            end if
        end tell
        """
        let existing = try runAppleScript(getGrouping)
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var combined = existing
        for tag in tags where !combined.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
            combined.append(tag)
        }

        let vibeString = combined.joined(separator: ", ")
        let escapedVibe = vibeString.replacingOccurrences(of: "\\", with: "\\\\")
                                    .replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Music"
            if player state is playing then
                set t to current track
                set grouping of t to "\(escapedVibe)"
                return name of t
            else
                error "Nothing is playing"
            end if
        end tell
        """
        let trackName = try runAppleScript(script)

        return "Set vibes on \(trackName)"
    }

    /// Plays the currently playing track in Apple Music (or resumes if paused).
    static func playSelectedTrack() throws {
        let script = """
        tell application "Music"
            if player state is not playing then
                play
            end if
        end tell
        """
        try runAppleScript(script)
    }

    /// Pauses playback in Apple Music.
    static func pause() throws {
        try runAppleScript("tell application \"Music\" to pause")
    }

    /// Returns true if the Music app is running, without sending it any Apple events
    /// (which would launch it if it weren't).
    static func isMusicRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.apple.Music" }
    }

    /// Returns true if Apple Music is currently playing.
    static func isPlaying() -> Bool {
        let script = """
        tell application "Music"
            if player state is playing then
                return "1"
            else
                return "0"
            end if
        end tell
        """
        return (try? runAppleScript(script)) == "1"
    }

    // MARK: - Private helpers

    @discardableResult
    private static func runAppleScript(_ source: String) throws -> String {
        var error: NSDictionary?
        let script = NSAppleScript(source: source)!
        let result = script.executeAndReturnError(&error)

        if let error = error {
            let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            throw MusicServiceError.scriptError(message)
        }
        return result.stringValue ?? ""
    }

    /// Strips a leading "123 - " BPM prefix if present.
    private static func stripExistingBPMPrefix(from name: String) -> String {
        // Match pattern like "120 - " at the start
        if let range = name.range(of: #"^\d+\s*-\s*"#, options: .regularExpression) {
            return String(name[range.upperBound...])
        }
        return name
    }
}

// MARK: - Song Change Detection

extension Notification.Name {
    /// Posted when the currently playing track changes in Apple Music.
    static let musicTrackDidChange = Notification.Name("musicTrackDidChange")
}

/// Monitors Apple Music for track changes and posts notifications.
final class MusicTrackMonitor: NSObject, ObservableObject {
    static let shared = MusicTrackMonitor()

    @Published var currentTrack: TrackInfo?
    
    private var timer: Timer?
    private var lastTrackName: String = ""

    private override init() {
        super.init()
        startMonitoring()
    }

    /// Starts monitoring for track changes (polls every 0.5 seconds).
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForTrackChange()
        }
    }

    /// Checks if the current track has changed.
    private func checkForTrackChange() {
        // Skip polling entirely when Music isn't running, so we never launch it
        guard MusicService.isMusicRunning() else { return }
        do {
            let info = try MusicService.getSelectedTrackInfo()
            if info.name != lastTrackName && !info.name.isEmpty {
                lastTrackName = info.name
                DispatchQueue.main.async {
                    self.currentTrack = info
                }
                NotificationCenter.default.post(name: .musicTrackDidChange, object: info)
            }
        } catch {
            // Music not playing or error reading track — silence this
        }
    }

    deinit {
        timer?.invalidate()
    }
}
