//
//  BPMRange.swift
//  AutoBPM
//
//  Created by James Lok on 2026-02-28.
//

import Foundation
import Combine

struct BPMRange: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var min: Int?
    var max: Int?
    
    func contains(bpm: Int) -> Bool {
        guard bpm > 0 else { return false }
        switch (min, max) {
        case let (lo?, hi?): return bpm >= lo && bpm <= hi
        case let (lo?, nil): return bpm >= lo
        case let (nil, hi?): return bpm <= hi
        case (nil, nil):     return false
        }
    }
}

// MARK: - Persistence via UserDefaults

final class BPMRangeStore: ObservableObject {
    @Published var ranges: [BPMRange] {
        didSet { save() }
    }
    
    private let key = "bpmRanges"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([BPMRange].self, from: data) {
            ranges = decoded
        } else {
            ranges = [
                BPMRange(name: "Recovery",  min: 70, max: 75),
                BPMRange(name: "Slow jog", min: 80, max: 90),
                BPMRange(name: "Fast jog",    min: 91,  max: 105),
                BPMRange(name: "Sprint",   min: 120, max: 140),
                BPMRange(name: "Climb", min: 60,  max: 68),
            ]
        }
    }
    
    func matchingRange(for bpm: Int) -> BPMRange? {
        ranges.first { $0.contains(bpm: bpm) }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(ranges) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
