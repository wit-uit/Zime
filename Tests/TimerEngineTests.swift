import Foundation

@main
struct TimerEngineTests {
    @MainActor
    static func main() {
        let start = Date(timeIntervalSince1970: 1_000_000)

        let paused = TimerEngine()
        paused.toggle(now: start)
        paused.tick(now: start.addingTimeInterval(73))
        expect(paused.remaining == 1427, "Delayed tick uses actual elapsed time")
        paused.toggle(now: start.addingTimeInterval(73))
        paused.tick(now: start.addingTimeInterval(500))
        expect(paused.remaining == 1427 && !paused.isRunning, "Pause freezes time")
        paused.toggle(now: start.addingTimeInterval(500))
        paused.tick(now: start.addingTimeInterval(527))
        expect(paused.remaining == 1400, "Resume preserves remaining duration")

        let automatic = TimerEngine()
        automatic.toggle(now: start)
        automatic.tick(now: start.addingTimeInterval(1500))
        expect(automatic.phase == .rest && automatic.remaining == 300, "Focus transitions to rest at exact deadline")
        expect(automatic.completedFocusSessions == 1 && automatic.isRunning, "Completed focus counted once")
        automatic.tick(now: start.addingTimeInterval(1800))
        expect(automatic.phase == .focus && automatic.remaining == 1500, "Rest transitions to focus")
        expect(automatic.completedPhases == 2, "Both phase completions recorded")

        let sleep = TimerEngine()
        sleep.toggle(now: start)
        sleep.tick(now: start.addingTimeInterval(1800 * 10000 + 1517))
        expect(sleep.phase == .rest && sleep.remaining == 283, "Long sleep catches up across cycles")
        expect(sleep.completedFocusSessions == 10001, "Missed sessions count correctly")
        expect(sleep.completedPhases == 20001, "Missed phases count correctly")

        let manual = TimerEngine()
        manual.automaticallyContinue = false
        manual.toggle(now: start)
        manual.tick(now: start.addingTimeInterval(9000))
        expect(manual.phase == .rest && manual.remaining == 300 && !manual.isRunning,
               "Manual continuation waits at next phase, even after sleep")
        expect(manual.completedFocusSessions == 1, "Manual continuation counts only finished phase")

        let changed = TimerEngine()
        changed.toggle(now: start)
        changed.configure(focusMinutes: 50, restMinutes: 10, now: start.addingTimeInterval(60))
        expect(changed.sessionDuration == 1500 && changed.remaining == 1440,
               "Duration edit preserves active session")
        changed.tick(now: start.addingTimeInterval(1500))
        expect(changed.phase == .rest && changed.remaining == 600, "Next phase uses updated setting")
        changed.reset()
        changed.select(.focus)
        expect(changed.remaining == 3000 && !changed.isRunning, "Reset and select use new settings")

        let idle = TimerEngine()
        idle.configure(focusMinutes: 45, restMinutes: 7, now: start)
        expect(idle.remaining == 2700 && idle.sessionDuration == 2700, "Idle settings apply immediately")
        idle.toggle(now: start)
        idle.skip(now: start.addingTimeInterval(20))
        expect(idle.phase == .rest && idle.remaining == 420 && idle.isRunning, "Skip preserves running state")
        expect(idle.completedFocusSessions == 0, "Skipped session does not count as completed")
        idle.reset()
        expect(idle.progress == 1 && !idle.isRunning, "Reset restores full dial and stops")
        print("PASS: 19 timer assertions")
    }

    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError("FAIL: \(message)") }
    }
}
