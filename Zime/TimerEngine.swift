import Foundation
import Observation

enum TimerPhase: String {
    case focus, rest

    var title: String { self == .focus ? "勉強" : "休憩" }
    var next: TimerPhase { self == .focus ? .rest : .focus }
}

/// Uses a deadline instead of counting timer callbacks, so sleep and delayed ticks
/// do not make a session run slowly.
@MainActor @Observable
final class TimerEngine {
    private(set) var phase: TimerPhase = .focus
    private(set) var isRunning = false
    private(set) var remaining: TimeInterval
    private(set) var sessionDuration: TimeInterval
    private(set) var completedFocusSessions = 0
    private(set) var completedPhases = 0
    private var deadline: Date?
    private var focusDuration: TimeInterval
    private var restDuration: TimeInterval
    var automaticallyContinue = true

    var progress: Double { min(1, max(0, remaining / sessionDuration)) }
    var isPristine: Bool { !isRunning && remaining == sessionDuration }
    var timeLabel: String {
        let seconds = max(0, Int(ceil(remaining)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    init(focusMinutes: Int = 25, restMinutes: Int = 5) {
        let initialDuration = Double(max(1, focusMinutes)) * 60
        focusDuration = initialDuration
        restDuration = Double(max(1, restMinutes)) * 60
        sessionDuration = initialDuration
        remaining = initialDuration
    }

    func configure(focusMinutes: Int, restMinutes: Int, now: Date = .now) {
        tick(now: now)
        focusDuration = Double(max(1, focusMinutes)) * 60
        restDuration = Double(max(1, restMinutes)) * 60
        if isPristine { reset() }
    }

    func toggle(now: Date = .now) {
        if isRunning {
            tick(now: now)
            isRunning = false
            deadline = nil
        } else {
            deadline = now.addingTimeInterval(remaining)
            isRunning = true
        }
    }

    func reset() {
        isRunning = false
        deadline = nil
        sessionDuration = duration(for: phase)
        remaining = sessionDuration
    }

    func select(_ newPhase: TimerPhase) {
        guard phase != newPhase else { return }
        phase = newPhase
        reset()
    }

    func skip(now: Date = .now) {
        let wasRunning = isRunning
        phase = phase.next
        reset()
        if wasRunning { toggle(now: now) }
    }

    func tick(now: Date = .now) {
        guard isRunning, let deadline else { return }
        guard now >= deadline else {
            remaining = deadline.timeIntervalSince(now)
            return
        }

        completePhase()
        if !automaticallyContinue {
            phase = phase.next
            reset()
            return
        }

        // Skip whole cycles arithmetically after long sleep, then at most two
        // phase boundaries. Never loop once per missed second or session.
        var overshoot = now.timeIntervalSince(deadline)
        phase = phase.next
        let cycle = focusDuration + restDuration
        let cycles = Int(overshoot / cycle)
        completedFocusSessions += cycles
        completedPhases += cycles * 2
        overshoot -= Double(cycles) * cycle
        if overshoot >= duration(for: phase) {
            overshoot -= duration(for: phase)
            completePhase()
            phase = phase.next
        }
        sessionDuration = duration(for: phase)
        remaining = sessionDuration - overshoot
        self.deadline = now.addingTimeInterval(remaining)
    }

    private func duration(for phase: TimerPhase) -> TimeInterval {
        phase == .focus ? focusDuration : restDuration
    }

    private func completePhase() {
        completedPhases += 1
        if phase == .focus { completedFocusSessions += 1 }
    }
}
