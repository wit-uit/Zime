import Foundation
import Observation

enum TimerPhase: String {
    case focus, rest

    var title: String { self == .focus ? "勉強" : "休憩" }
    var next: TimerPhase { self == .focus ? .rest : .focus }
}

enum TimerStage {
    case idle, preparing, timing
}

/// Uses a deadline instead of counting timer callbacks, so sleep and delayed ticks
/// do not make a session run slowly.
@MainActor @Observable
final class TimerEngine {
    static let preparationDuration: TimeInterval = 1.2
    private(set) var phase: TimerPhase = .focus
    private(set) var stage: TimerStage = .idle
    private(set) var isRunning = false
    private(set) var remaining: TimeInterval
    private(set) var sessionDuration: TimeInterval
    private(set) var completedFocusSessions = 0
    private(set) var completedPhases = 0
    private var deadline: Date?
    private var preparationDeadline: Date?
    private var preparationRemaining = TimerEngine.preparationDuration
    private var focusDuration: TimeInterval
    private var restDuration: TimeInterval
    var automaticallyContinue = true

    var progress: Double { min(1, max(0, remaining / sessionDuration)) }
    var elapsedProgress: Double { 1 - progress }
    var isPreparing: Bool { stage == .preparing }
    var isPristine: Bool { stage == .idle }
    var dialFraction: Double { dialFraction(at: .now) }

    // All colored sectors extend counterclockwise from twelve o'clock.
    // Decreasing this fraction therefore removes color clockwise during focus.
    func dialFraction(at now: Date) -> Double {
        if stage == .preparing {
            let remaining = preparationDeadline.map { $0.timeIntervalSince(now) } ?? preparationRemaining
            return min(1, max(0, 1 - remaining / Self.preparationDuration))
        }
        if stage == .idle { return 0 }
        return phase == .focus ? progress : elapsedProgress
    }
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
        if stage != .timing {
            sessionDuration = duration(for: phase)
            remaining = sessionDuration
        }
    }

    func toggle(now: Date = .now) {
        if isRunning {
            tick(now: now)
            isRunning = false
            deadline = nil
            preparationDeadline = nil
        } else {
            if stage == .idle { stage = phase == .focus ? .preparing : .timing }
            if stage == .preparing {
                preparationDeadline = now.addingTimeInterval(preparationRemaining)
            } else {
                deadline = now.addingTimeInterval(remaining)
            }
            isRunning = true
        }
    }

    func reset() {
        isRunning = false
        stage = .idle
        deadline = nil
        preparationDeadline = nil
        preparationRemaining = Self.preparationDuration
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
        stage = .timing
        if wasRunning { toggle(now: now) }
    }

    func tick(now: Date = .now) {
        guard isRunning else { return }
        if stage == .preparing, let preparationDeadline {
            preparationRemaining = max(0, preparationDeadline.timeIntervalSince(now))
            guard now >= preparationDeadline else { return }
            stage = .timing
            self.preparationDeadline = nil
            deadline = preparationDeadline.addingTimeInterval(remaining)
        }
        guard let deadline else { return }
        guard now >= deadline else {
            remaining = deadline.timeIntervalSince(now)
            return
        }

        completePhase()
        if !automaticallyContinue {
            phase = phase.next
            reset()
            stage = .timing
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
