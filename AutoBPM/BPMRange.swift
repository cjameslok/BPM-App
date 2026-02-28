//
//  BPMRange.swift
//  AutoBPM
//
//  Created by James Lok on 2026-02-28.
//

import Foundation
internal import Combine

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
            // Sensible defaults for fitness instructors
            ranges = [
                BPMRange(name: "Warm-up",  min: 100, max: 115),
                BPMRange(name: "Flat Road", min: 116, max: 128),
                BPMRange(name: "Climb",    min: 60,  max: 80),
                BPMRange(name: "Sprint",   min: 130, max: 160),
                BPMRange(name: "Cooldown", min: 80,  max: 100),
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
