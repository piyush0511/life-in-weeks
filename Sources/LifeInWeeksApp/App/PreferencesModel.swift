import Combine
import Foundation
import LifeInWeeksCore

@MainActor
final class PreferencesModel: ObservableObject {
    @Published var settings: LifeCalendarSettings {
        didSet {
            store.save(settings)
            handleAutoDetectChange(
                old: oldValue.autoDetectNextDestination,
                new: settings.autoDetectNextDestination
            )
        }
    }

    @Published private(set) var now: Date = Date()

    let travelDetector = CalendarTravelDetector()

    private let store: PreferencesStore
    private var tickCancellable: AnyCancellable?
    private var detectorCancellable: AnyCancellable?

    init(store: PreferencesStore = PreferencesStore()) {
        self.store = store
        self.settings = store.load()
        startTicker()
        bindDetector()
        if settings.autoDetectNextDestination {
            travelDetector.refreshAvailableCalendars()
            Task {
                await travelDetector.refresh(
                    allowedCalendarIDs: settings.enabledCalendarIdentifiers
                )
            }
        }
    }

    func reset() {
        settings = .defaults
        store.reset()
    }

    /// Destination shown on the wallpaper. Auto-detected trip wins when
    /// the toggle is on and detection succeeded; otherwise the user's
    /// manually-typed value is used.
    var effectiveNextDestination: String {
        if settings.autoDetectNextDestination,
            let trip = travelDetector.detectedTrip
        {
            return trip.destination
        }
        return settings.nextDestination
    }

    func refreshTravelDetectorIfNeeded() async {
        guard settings.autoDetectNextDestination else { return }
        await travelDetector.refresh(
            allowedCalendarIDs: settings.enabledCalendarIdentifiers
        )
    }

    private func bindDetector() {
        // Surface detector state as changes to our own object so that any
        // SwiftUI view observing the model rebuilds when a trip is detected.
        detectorCancellable =
            travelDetector
            .objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }

    private func handleAutoDetectChange(old: Bool, new: Bool) {
        guard old != new else { return }
        if new {
            Task {
                let granted = await travelDetector.requestAccess(
                    allowedCalendarIDs: settings.enabledCalendarIdentifiers
                )
                _ = granted
            }
        }
    }

    private func startTicker() {
        tickCancellable =
            Timer.publish(every: 60 * 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.now = date
                Task { await self?.refreshTravelDetectorIfNeeded() }
            }
    }
}
