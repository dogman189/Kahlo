import Foundation
import BackgroundTasks
import UIKit

/// Manages background execution of the trading bot using BGTaskScheduler.
/// This allows the app to be woken up periodically by the OS to run bot ticks
/// even when the app is not in the foreground.
public final class BackgroundTaskManager {
    public static let shared = BackgroundTaskManager()

    // BGTaskScheduler identifiers — must also be listed in Info.plist
    // under UIBackgroundModes / BGTaskSchedulerPermittedIdentifiers.
    public static let appRefreshIdentifier = "ultraexchange.Kahlo.refresh"
    public static let processingIdentifier = "ultraexchange.Kahlo.processing"

    /// Weak reference to the trading engine so we can call botTick without
    /// creating a retain cycle.
    public weak var engine: TradingEngine?

    /// Background task identifier for UIKit's beginBackgroundTask, used to
    /// buy extra time (≤ 30 s) immediately after the app enters the background.
    private var uiBackgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    private init() {}

    // MARK: - Registration

    /// Call this once at app launch inside the @main struct body, BEFORE the
    /// app finishes launching.  BGTaskScheduler requires handlers to be
    /// registered before the first runloop iteration completes.
    public func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskManager.appRefreshIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleAppRefresh(task: task as! BGAppRefreshTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskManager.processingIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleProcessingTask(task: task as! BGProcessingTask)
        }
    }

    // MARK: - Scheduling

    /// Schedule a BGAppRefreshTask. The OS will decide the exact wakeup time
    /// but will try to respect the `earliestBeginDate`. Call this every time
    /// the app enters the background while the bot is running.
    public func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: BackgroundTaskManager.appRefreshIdentifier)
        // Ask for a wakeup as soon as possible (OS may delay based on battery / usage)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BGTask] App refresh task scheduled.")
        } catch {
            print("[BGTask] Could not schedule app refresh: \(error)")
        }
    }

    /// Schedule a longer-running BGProcessingTask for sustained work.
    public func scheduleProcessingTask() {
        let request = BGProcessingTaskRequest(identifier: BackgroundTaskManager.processingIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BGTask] Processing task scheduled.")
        } catch {
            print("[BGTask] Could not schedule processing task: \(error)")
        }
    }

    // MARK: - Handlers

    private func handleAppRefresh(task: BGAppRefreshTask) {
        print("[BGTask] App refresh handler invoked.")

        // Re-schedule the next refresh immediately so we keep getting wakeups.
        scheduleAppRefresh()

        guard let engine = engine, engine.isRunning else {
            task.setTaskCompleted(success: true)
            return
        }

        // Run one bot tick inside a Swift concurrency Task, then complete.
        let botTask = Task {
            await engine.botTickBackground()
            task.setTaskCompleted(success: true)
        }

        // If the OS wants to expire the task before we finish, cancel cleanly.
        task.expirationHandler = {
            botTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    private func handleProcessingTask(task: BGProcessingTask) {
        print("[BGTask] Processing task handler invoked.")

        // Re-schedule.
        scheduleProcessingTask()

        guard let engine = engine, engine.isRunning else {
            task.setTaskCompleted(success: true)
            return
        }

        // Run several ticks while we have extended time.
        let botTask = Task {
            for _ in 0..<5 {
                guard !Task.isCancelled else { break }
                await engine.botTickBackground()
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 s between ticks
            }
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            botTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    // MARK: - UIKit Short-Duration Background Time

    /// Call when the app transitions to the background to grab up to ~30 s of
    /// extra execution time.  This lets the current bot tick finish cleanly.
    public func beginUIBackgroundTask() {
        guard uiBackgroundTaskID == .invalid else { return }
        uiBackgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "KahloTradingBotTick") {
            // Expiration handler: end the task immediately.
            self.endUIBackgroundTask()
        }
        print("[BGTask] UIBackgroundTask started (id: \(uiBackgroundTaskID.rawValue)).")
    }

    /// Must be called to tell the OS we are done with the short-duration task.
    public func endUIBackgroundTask() {
        guard uiBackgroundTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(uiBackgroundTaskID)
        uiBackgroundTaskID = .invalid
        print("[BGTask] UIBackgroundTask ended.")
    }
}
