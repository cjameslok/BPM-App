import Testing
import Foundation
@testable import AutoBPM

struct BPMRangeTests {

    @Test func containsBPMInRange() {
        let range = BPMRange(name: "Test", min: 100, max: 120)
        #expect(range.contains(bpm: 100))
        #expect(range.contains(bpm: 110))
        #expect(range.contains(bpm: 120))
        #expect(!range.contains(bpm: 99))
        #expect(!range.contains(bpm: 121))
    }

    @Test func openEndedMax() {
        let range = BPMRange(name: "Fast", min: 150, max: nil)
        #expect(range.contains(bpm: 150))
        #expect(range.contains(bpm: 200))
        #expect(!range.contains(bpm: 149))
    }

    @Test func openEndedMin() {
        let range = BPMRange(name: "Slow", min: nil, max: 80)
        #expect(range.contains(bpm: 80))
        #expect(range.contains(bpm: 50))
        #expect(!range.contains(bpm: 81))
    }

    @Test func nilBothReturnsFalse() {
        let range = BPMRange(name: "Empty", min: nil, max: nil)
        #expect(!range.contains(bpm: 100))
    }

    @Test func zeroBPMReturnsFalse() {
        let range = BPMRange(name: "Test", min: 0, max: 200)
        #expect(!range.contains(bpm: 0))
    }
}

struct BPMRangeStoreTests {

    @Test func matchingRangeFindsCorrectRange() {
        let store = BPMRangeStore()
        let match = store.matchingRange(for: 110)
        #expect(match != nil)
        #expect(match?.name == "Warm-up")
    }

    @Test func matchingRangeReturnsNilForUnmatched() {
        let store = BPMRangeStore()
        let match = store.matchingRange(for: 200)
        #expect(match == nil)
    }

    @Test func matchingRangeReturnsFirstMatch() {
        let store = BPMRangeStore()
        let match = store.matchingRange(for: 100)
        #expect(match != nil)
    }
}
