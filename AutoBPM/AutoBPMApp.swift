//
//  AutoBPMApp.swift
//  AutoBPM
//
//  Created by James Lok on 2026-02-28.
//

import SwiftUI

@main
struct AutoBPMApp: App {
    @State private var calculator = BPMCalculator()
    @StateObject private var rangeStore = BPMRangeStore()
    
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
