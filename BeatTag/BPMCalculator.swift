//
//  BPMCalculator.swift
//  BeatTag
//
//  Created by James Lok on 2026-02-28.
//

import Foundation
import Observation

@Observable
final class BPMCalculator {
    private(set) var bpm: Double = 0
    private(set) var tapCount: Int = 0
    private var tapTimestamps: [Date] = []
    
    /// Maximum time between taps before resetting (seconds)
    private let resetInterval: TimeInterval = 3.0
    
    func tap() {
        let now = Date()
        
        // Reset if too long since last tap
        if let lastTap = tapTimestamps.last,
           now.timeIntervalSince(lastTap) > resetInterval {
            reset()
        }
        
        tapTimestamps.append(now)
        tapCount = tapTimestamps.count
        calculateBPM()
    }
    
    func reset() {
        tapTimestamps.removeAll()
        tapCount = 0
        bpm = 0
    }
    
    private func calculateBPM() {
        guard tapTimestamps.count >= 2 else {
            bpm = 0
            return
        }
        
        let totalInterval = tapTimestamps.last!.timeIntervalSince(tapTimestamps.first!)
        let numberOfIntervals = Double(tapTimestamps.count - 1)
        let averageInterval = totalInterval / numberOfIntervals
        
        bpm = 60.0 / averageInterval
    }
}
