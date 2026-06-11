//
//  KahloApp.swift
//  Kahlo
//
//  Created by Aanetra Vaidya on 6/8/26.
//

import SwiftUI
import BackgroundTasks

@main
struct KahloApp: App {
    /// Shared engine instance — owned here so BackgroundTaskManager can hold
    /// a weak reference to it before ContentView is created.
    @StateObject private var engine = TradingEngine()

    init() {
        // Background task handlers MUST be registered before the first
        // runloop iteration completes, so we do it here in init().
        BackgroundTaskManager.shared.registerTasks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(engine: engine)
                .onAppear {
                    // Give BackgroundTaskManager a weak ref to the engine so
                    // BGTask handlers can drive bot ticks.
                    BackgroundTaskManager.shared.engine = engine
                }
        }
    }
}
