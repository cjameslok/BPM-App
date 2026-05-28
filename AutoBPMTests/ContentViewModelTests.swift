import Testing
import Foundation
@testable import AutoBPM

@MainActor
struct ContentViewModelTests {

    private func makeVM() -> ContentViewModel {
        ContentViewModel(calculator: BPMCalculator(), rangeStore: BPMRangeStore())
    }

    @Test func initialState() {
        let vm = makeVM()
        #expect(vm.roundedBPM == 0)
        #expect(vm.statusMessage == nil)
        #expect(vm.isError == false)
        #expect(vm.selectedTags.isEmpty)
        #expect(vm.vibeStatusMessage == nil)
        #expect(vm.showSettings == false)
    }

    @Test func tapDelegatesToCalculator() {
        let vm = makeVM()
        vm.tap()
        #expect(vm.calculator.tapCount == 1)
    }

    @Test func resetClearsCalculatorAndStatus() {
        let vm = makeVM()
        vm.tap()
        vm.statusMessage = "test"
        vm.reset()
        #expect(vm.calculator.tapCount == 0)
        #expect(vm.statusMessage == nil)
    }

    @Test func toggleTagAddsAndRemoves() {
        let vm = makeVM()
        vm.toggleTag("Chill")
        #expect(vm.selectedTags.contains("Chill"))
        vm.toggleTag("Chill")
        #expect(!vm.selectedTags.contains("Chill"))
    }

    @Test func addCustomTagAppendsAndSelects() {
        let vm = makeVM()
        vm.customTagInput = "MyTag"
        vm.addCustomTag()
        #expect(vm.availableTags.contains("MyTag"))
        #expect(vm.selectedTags.contains("MyTag"))
        #expect(vm.customTagInput.isEmpty)
    }

    @Test func addCustomTagIgnoresEmpty() {
        let vm = makeVM()
        vm.customTagInput = "   "
        let countBefore = vm.availableTags.count
        vm.addCustomTag()
        #expect(vm.availableTags.count == countBefore)
    }

    @Test func addCustomTagDoesNotDuplicate() {
        let vm = makeVM()
        vm.customTagInput = "Chill"
        let countBefore = vm.availableTags.count
        vm.addCustomTag()
        #expect(vm.availableTags.count == countBefore)
        #expect(vm.selectedTags.contains("Chill"))
    }

    @Test func removeTagRemovesFromBothSets() {
        let vm = makeVM()
        vm.toggleTag("Chill")
        vm.removeTag("Chill")
        #expect(!vm.availableTags.contains("Chill"))
        #expect(!vm.selectedTags.contains("Chill"))
    }

    @Test func isPresetTagIdentifiesPresets() {
        let vm = makeVM()
        #expect(vm.isPresetTag("Chill"))
        #expect(vm.isPresetTag("Hype"))
        #expect(!vm.isPresetTag("CustomTag"))
    }

    @Test func resetVibeClearsSelectionAndMessage() {
        let vm = makeVM()
        vm.toggleTag("Chill")
        vm.vibeStatusMessage = "Done"
        vm.resetVibe()
        #expect(vm.selectedTags.isEmpty)
        #expect(vm.vibeStatusMessage == nil)
    }

    @Test func roundedBPMReflectsCalculator() {
        let vm = makeVM()
        vm.tap()
        Thread.sleep(forTimeInterval: 0.5)
        vm.tap()
        #expect(vm.roundedBPM > 0)
    }
}
