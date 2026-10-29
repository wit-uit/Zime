import Foundation

@main
struct TimerEngineTests {
    @MainActor private static var assertionCount = 0

    @MainActor
    static func main() {
        let start = Date(timeIntervalSince1970: 1_000_000)

        let paused = TimerEngine()
        startTiming(paused, at: start)
        paused.tick(now: start.addingTimeInterval(73))
        expect(paused.remaining == 1427, "Delayed tick uses actual elapsed time")
        paused.toggle(now: start.addingTimeInterval(73))
        paused.tick(now: start.addingTimeInterval(500))
        expect(paused.remaining == 1427 && !paused.isRunning, "Pause freezes time")
        paused.toggle(now: start.addingTimeInterval(500))
        paused.tick(now: start.addingTimeInterval(527))
        expect(paused.remaining == 1400, "Resume preserves remaining duration")

        let automatic = TimerEngine()
        expect(automatic.elapsedProgress == 0, "Dial starts empty")
        startTiming(automatic, at: start)
        automatic.tick(now: start.addingTimeInterval(375))
        expect(automatic.elapsedProgress == 0.25, "Focus elapsed fraction tracks time")
        expect(automatic.dialFraction == 0.75, "Focus color decreases from a full dial")
        automatic.tick(now: start.addingTimeInterval(1500))
        expect(automatic.phase == .rest && automatic.remaining == 300, "Focus transitions to rest at exact deadline")
        expect(automatic.completedFocusSessions == 1 && automatic.isRunning, "Completed focus counted once")
        expect(automatic.elapsedProgress == 0, "Rest starts with an empty dial")
        expect(automatic.dialFraction == 0, "Focus finishes empty and rest begins empty")
        automatic.tick(now: start.addingTimeInterval(1575))
        expect(automatic.elapsedProgress == 0.25, "Rest dial also fills with elapsed time")
        expect(automatic.dialFraction == 0.25, "Rest color grows with elapsed time")
        automatic.tick(now: start.addingTimeInterval(1800))
        expect(automatic.phase == .focus && automatic.remaining == 1500, "Rest transitions to focus")
        expect(automatic.completedPhases == 2, "Both phase completions recorded")
        expect(automatic.dialFraction == 1, "Rest ends full, ready for the next focus without another preparation")

        let sleep = TimerEngine()
        startTiming(sleep, at: start)
        sleep.tick(now: start.addingTimeInterval(1800 * 10000 + 1517))
        expect(sleep.phase == .rest && sleep.remaining == 283, "Long sleep catches up across cycles")
        expect(sleep.completedFocusSessions == 10001, "Missed sessions count correctly")
        expect(sleep.completedPhases == 20001, "Missed phases count correctly")

        let manual = TimerEngine()
        manual.automaticallyContinue = false
        startTiming(manual, at: start)
        manual.tick(now: start.addingTimeInterval(9000))
        expect(manual.phase == .rest && manual.remaining == 300 && !manual.isRunning,
               "Manual continuation waits at next phase, even after sleep")
        expect(manual.completedFocusSessions == 1, "Manual continuation counts only finished phase")

        let changed = TimerEngine()
        startTiming(changed, at: start)
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
        startTiming(idle, at: start)
        idle.skip(now: start.addingTimeInterval(20))
        expect(idle.phase == .rest && idle.remaining == 420 && idle.isRunning, "Skip preserves running state")
        expect(idle.completedFocusSessions == 0, "Skipped session does not count as completed")
        idle.reset()
        expect(idle.progress == 1 && !idle.isRunning, "Reset restores duration and stops")
        let preparing = TimerEngine()
        expect(preparing.dialFraction == 0, "Initial dial is empty")
        preparing.toggle(now: start)
        preparing.tick(now: start.addingTimeInterval(0.6))
        expect(preparing.isPreparing && preparing.isRunning, "Start enters preparation")
        expect(preparing.remaining == 1500, "Preparation does not consume focus time")
        expect(abs(preparing.dialFraction(at: start.addingTimeInterval(0.6)) - 0.5) < 0.000001,
               "Preparation fills halfway in 0.6 seconds")
        preparing.tick(now: start.addingTimeInterval(1.2))
        expect(!preparing.isPreparing && preparing.remaining == 1500, "Focus starts after exactly 1.2 seconds")
        expect(preparing.dialFraction == 1, "Focus begins with full color")
        preparing.tick(now: start.addingTimeInterval(61.2))
        expect(abs(preparing.remaining - 1440) < 0.000001, "Focus duration excludes preparation")

        let pausedPreparation = TimerEngine()
        pausedPreparation.toggle(now: start)
        pausedPreparation.toggle(now: start.addingTimeInterval(0.3))
        expect(pausedPreparation.isPreparing && !pausedPreparation.isRunning, "Preparation can pause")
        expect(abs(pausedPreparation.dialFraction(at: start.addingTimeInterval(50)) - 0.25) < 0.000001,
               "Paused preparation remains frozen")
        pausedPreparation.toggle(now: start.addingTimeInterval(50))
        pausedPreparation.tick(now: start.addingTimeInterval(50.8))
        expect(pausedPreparation.isPreparing, "Resumed preparation retains its remaining fill time")
        pausedPreparation.tick(now: start.addingTimeInterval(51.9))
        expect(!pausedPreparation.isPreparing && abs(pausedPreparation.remaining - 1499) < 0.000001,
               "Resumed preparation starts the complete focus duration")

        let cancelled = TimerEngine()
        cancelled.toggle(now: start)
        cancelled.reset()
        cancelled.tick(now: start.addingTimeInterval(10))
        expect(!cancelled.isRunning && !cancelled.isPreparing && cancelled.dialFraction == 0,
               "Reset cancels preparation and clears the dial")
        cancelled.toggle(now: start)
        cancelled.skip(now: start.addingTimeInterval(0.3))
        expect(cancelled.phase == .rest && cancelled.isRunning && !cancelled.isPreparing,
               "Skip cancels preparation and starts rest")
        expect(cancelled.completedFocusSessions == 0, "Cancelled preparation is not a completed session")

        let delayedPreparation = TimerEngine()
        delayedPreparation.toggle(now: start)
        delayedPreparation.tick(now: start.addingTimeInterval(1518.2))
        expect(delayedPreparation.phase == .rest && abs(delayedPreparation.remaining - 283) < 0.000001,
               "A delayed preparation callback catches up using the original deadline")
        print("PASS: \(assertionCount) timer assertions")
    }

    @MainActor
    static func startTiming(_ timer: TimerEngine, at start: Date) {
        timer.toggle(now: start.addingTimeInterval(-TimerEngine.preparationDuration))
        timer.tick(now: start)
    }

    @MainActor
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        assertionCount += 1
        guard condition() else { fatalError("FAIL: \(message)") }
    }
}
