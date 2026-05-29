//
//  AutoBPMApp.swift
//  AutoBPM
//
//  Created by James Lok on 2026-02-28.
//

import SwiftUI
import AppKit

@main
struct AutoBPMApp: App {
    @State private var calculator = BPMCalculator()
    @StateObject private var rangeStore = BPMRangeStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra {
            ContentView(calculator: calculator, rangeStore: rangeStore)
        } label: {
            Label(
                calculator.bpm > 0 ? "\(Int(calculator.bpm.rounded())) BPM" : "BPM",
                systemImage: "metronome"
            )
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemObserver: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Monitor right-click events on the status bar
        statusItemObserver = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseUp]) { event in
            // Check if the right-click is on a status bar button
            if let window = event.window,
               window.className.contains("NSStatusBar") || window.level == .statusBar {
                let menu = NSMenu()
                if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                    menu.appearance = NSAppearance(named: .darkAqua)
                }
                menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
                
                // Show the menu at the click location
                if let button = window.contentView {
                    NSMenu.popUpContextMenu(menu, with: event, for: button)
                    return nil
                }
            }
            return event
        }
    }
}
