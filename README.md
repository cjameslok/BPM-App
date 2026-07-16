# BeatTag

A lightweight macOS menu bar app for fitness instructors and DJs to tap tempo, tag vibes, and sync BPM data directly to Apple Music tracks with the click of a button.

![macOS](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![Architecture](https://img.shields.io/badge/architecture-MVVM-green)

<img width="200" alt="Screenshot 1" src="https://github.com/user-attachments/assets/8970a88e-26ba-4677-8f6b-288af081e839" />
<img width="200" alt="Screenshot 2" src="https://github.com/user-attachments/assets/6c6eb5a1-1b92-4cc3-8293-4f87177fe382" />


## How to use

1. Play a song from your library in the Apple Music app.
2. Open the menu bar app and start tapping to the beat with the space bar.
3. Click Enter to assign the value to the song's BPM field and prepend it to the track title.

<img width="800" src="https://github.com/user-attachments/assets/4ec25791-c3dd-4c70-9fe8-5b39d5e10926" />

## Features

### 🎵 Tap Tempo
- Tap the spacebar (or click) to calculate BPM in real time
- Averaged BPM from multiple taps for accuracy
- Auto-resets after 3 seconds of inactivity
- Double-click the BPM display to copy BPM to clipboard

### 🏷️ Vibe Tags
- Assign mood/vibe tags (e.g. Chill, Hype, Groovy) to the currently playing track
- Tags are written to the track's **Grouping** field in Apple Music
- Add custom tags or use the built-in presets
- Toggle vibe feature visibility in Settings

### 🎶 Apple Music Integration
- View currently playing track info (name, artist, BPM, grouping)
- Set tapped BPM directly onto the selected track
- Optionally prepend BPM to the track title (configurable in Settings)
- Play/pause control from the menu bar
- Auto-refreshes track info when the app gains focus or the track changes

### 📊 BPM Range Matching
- Configurable named BPM ranges (e.g. Warm-up: 100–115, Sprint: 130–160)
- Instantly see which category a tapped or track BPM falls into
- Add, edit, and remove ranges in Settings
- Persisted via UserDefaults

### ⚙️ Settings
- Uses the macOS system accent color (set in System Settings → Appearance)
- Toggle vibe tags feature on/off
- Toggle "Prepend BPM to song title" on/off
- Customizable BPM ranges

## Architecture

BeatTag follows **MVVM (Model-View-ViewModel)** architecture:

```
┌─────────────────────────────────────────────┐
│  Models                                     │
│  ├── BPMCalculator    (tap logic)           │
│  ├── BPMRange         (range model)         │
│  ├── BPMRangeStore    (persistence)         │
│  ├── MusicService     (AppleScript bridge)  │
│  └── MusicTrackMonitor (track change obs.)  │
├─────────────────────────────────────────────┤
│  ViewModel                                  │
│  └── ContentViewModel (state & logic)       │
├─────────────────────────────────────────────┤
│  Views                                      │
│  ├── ContentView      (main UI)             │
│  ├── SettingsView     (preferences)         │
│  ├── TagChip          (tag component)       │
│  └── FlowLayout       (wrapping layout)     │
└─────────────────────────────────────────────┘
```

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode 15+
- Apple Music must be running for track integration features

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/BeatTag.git
   ```
2. Open `AutoBPM.xcodeproj` in Xcode
3. Build and run (⌘R)
4. The app appears in your menu bar with a metronome icon

## Usage

| Action | Shortcut |
|--------|----------|
| Tap tempo | `Space` |
| Set BPM to track | `Return` |
| Reset | `Delete` |
| Copy BPM | Double-click BPM display |

## Running Tests

Open the project in Xcode and run tests with ⌘U. Test files:

- `BPMCalculatorTests.swift` — tap logic, reset, BPM averaging
- `BPMRangeTests.swift` — range containment, edge cases
- `ContentViewModelTests.swift` — ViewModel state management, tag operations

## Permissions

BeatTag requires **Automation** permission to control Apple Music via AppleScript. macOS will prompt for this on first use.

## License

MIT
