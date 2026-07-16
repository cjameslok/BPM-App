import Testing
import Foundation
@testable import BeatTag

struct BPMCalculatorTests {

    @Test func initialState() {
        let calc = BPMCalculator()
        #expect(calc.bpm == 0)
        #expect(calc.tapCount == 0)
    }

    @Test func singleTapDoesNotProduceBPM() {
        let calc = BPMCalculator()
        calc.tap()
        #expect(calc.tapCount == 1)
        #expect(calc.bpm == 0)
    }

    @Test func twoTapsProduceBPM() {
        let calc = BPMCalculator()
        calc.tap()
        Thread.sleep(forTimeInterval: 0.5)
        calc.tap()
        #expect(calc.tapCount == 2)
        #expect(calc.bpm > 100 && calc.bpm < 140)
    }

    @Test func multipleTapsAverageBPM() {
        let calc = BPMCalculator()
        for _ in 0..<4 {
            calc.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        calc.tap()
        #expect(calc.tapCount == 5)
        #expect(calc.bpm > 100 && calc.bpm < 140)
    }

    @Test func resetClearsState() {
        let calc = BPMCalculator()
        calc.tap()
        Thread.sleep(forTimeInterval: 0.3)
        calc.tap()
        calc.reset()
        #expect(calc.bpm == 0)
        #expect(calc.tapCount == 0)
    }
}
