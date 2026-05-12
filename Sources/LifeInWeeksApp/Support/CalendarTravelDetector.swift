import EventKit
import Foundation
import LifeInWeeksCore

@MainActor
final class CalendarTravelDetector: ObservableObject {
    enum AccessState: Equatable {
        case notDetermined
        case authorized
        case denied
    }

    struct DetectedTrip: Equatable, Sendable {
        let destination: String
        let date: Date
        let sourceTitle: String
    }

    @Published private(set) var accessState: AccessState = .notDetermined
    @Published private(set) var detectedTrip: DetectedTrip?
    @Published private(set) var lastRefreshedAt: Date?
    @Published private(set) var availableCalendars: [CalendarOption] = []

    struct CalendarOption: Identifiable, Hashable, Sendable {
        let id: String           // EKCalendar.calendarIdentifier
        let title: String        // EKCalendar.title
        let sourceTitle: String  // EKCalendar.source.title (e.g. "Google", "iCloud")
        let cgColor: CGColor?
    }

    private let store = EKEventStore()
    private var storeChangeObserver: NSObjectProtocol?

    init() {
        refreshAccessState()
        observeStoreChanges()
    }

    private func observeStoreChanges() {
        // EventKit fires this when the underlying database changes (calendars
        // added/removed, events added, sync completed, etc.). Without this
        // observer, EKEventStore returns stale data — new calendars added in
        // Calendar.app won't show up until the store is recreated.
        storeChangeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.refreshAvailableCalendars()
                Task { await self.refresh() }
            }
        }
    }

    func refreshAccessState() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            accessState = .notDetermined
        case .denied, .restricted:
            accessState = .denied
        case .authorized:
            accessState = .authorized
        case .fullAccess:
            accessState = .authorized
        case .writeOnly:
            accessState = .denied
        @unknown default:
            accessState = .notDetermined
        }
    }

    func requestAccess(allowedCalendarIDs: Set<String> = []) async -> Bool {
        let granted: Bool
        if #available(macOS 14, *) {
            granted =
                (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            granted = await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { ok, _ in
                    cont.resume(returning: ok)
                }
            }
        }
        refreshAccessState()
        if granted {
            refreshAvailableCalendars()
            await refresh(allowedCalendarIDs: allowedCalendarIDs)
        }
        return granted
    }

    func refreshAvailableCalendars() {
        guard accessState == .authorized else {
            availableCalendars = []
            return
        }
        // Drop EventKit's internal cache so calendars added in Calendar.app
        // since the store was created are visible.
        store.reset()
        availableCalendars =
            store.calendars(for: .event)
            .sorted { lhs, rhs in
                if lhs.source.title != rhs.source.title {
                    return lhs.source.title < rhs.source.title
                }
                return lhs.title < rhs.title
            }
            .map { cal in
                CalendarOption(
                    id: cal.calendarIdentifier,
                    title: cal.title,
                    sourceTitle: cal.source.title,
                    cgColor: cal.cgColor
                )
            }
    }

    func refresh(allowedCalendarIDs: Set<String> = []) async {
        guard accessState == .authorized else {
            return
        }

        refreshAvailableCalendars()

        let now = Date()
        guard
            let horizon = Calendar.current.date(
                byAdding: .day, value: 120, to: now)
        else { return }

        // If the user has narrowed to specific calendars, only query those.
        // If the set is empty we treat it as "all" so first-time use works
        // without forcing a selection.
        let calendars: [EKCalendar]?
        if allowedCalendarIDs.isEmpty {
            calendars = nil
        } else {
            calendars =
                store.calendars(for: .event)
                .filter { allowedCalendarIDs.contains($0.calendarIdentifier) }
        }

        let predicate = store.predicateForEvents(
            withStart: now, end: horizon, calendars: calendars)
        let events = store.events(matching: predicate)

        // Only future-starting events count as "next destination". An event
        // that started yesterday (e.g. the user already arrived) is the
        // current location, not the next one.
        let scored =
            events
            .filter { $0.startDate > now }
            .compactMap { event -> (event: EKEvent, score: Int, trip: DetectedTrip)? in
                guard let (score, trip) = scoreEvent(event), score > 0 else {
                    return nil
                }
                return (event, score, trip)
            }
            .sorted { lhs, rhs in
                if lhs.event.startDate != rhs.event.startDate {
                    return lhs.event.startDate < rhs.event.startDate
                }
                return lhs.score > rhs.score
            }

        detectedTrip = scored.first?.trip
        lastRefreshedAt = Date()
    }

    // MARK: - Detection heuristics

    /// Hotel/hostel/Airbnb events are NOT trips — they're accommodation
    /// (often inserted automatically by Gmail when you book a stay). They
    /// match enough travel keywords to score positive without this filter.
    private static let accommodationKeywords: [String] = [
        "hotel", "hostel", "hostal", "airbnb", "booking.com",
        "guesthouse", "guest house", "bed and breakfast", "b&b",
        "inn", "lodge", "resort", "motel",
        "stay at", "stay in", "check-in", "check-out", "checkin", "checkout",
        "accommodation", "apartment", "vrbo", "agoda", "hostelworld",
        "reservation:",
    ]

    /// Strong indicators that an event really is a flight/trip and not just
    /// an accommodation booking with stray travel words in it.
    private static let flightKeywords: [String] = [
        "✈", "flight", "flug", "vol ", "fly to", "fly from",
        "boarding", "departure", "departs", "arrives at",
        "airline", "airport",
    ]

    /// Score an event for travel-likeness. Higher score = more likely a trip.
    /// Returns (score, trip) if score > 0.
    private func scoreEvent(_ event: EKEvent) -> (Int, DetectedTrip)? {
        let title = event.title ?? ""
        let location = event.location ?? ""
        let combined = "\(title) \(location)".lowercased()

        // Hard reject: this is an accommodation booking. Only override if
        // the event ALSO contains a strong flight keyword (e.g., a combined
        // itinerary that mentions both).
        let isAccommodation = Self.accommodationKeywords.contains(where: combined.contains)
        let hasFlightKeyword = Self.flightKeywords.contains(where: combined.contains)
        if isAccommodation && !hasFlightKeyword {
            return nil
        }

        var score = 0

        let keywords: [(String, Int)] = [
            ("✈", 6), ("flight", 5), ("flug", 5), ("departure", 3),
            ("airport", 3), ("boarding", 3), ("itinerary", 3),
            ("trip to", 4), ("travel to", 4), ("fly to", 4),
            ("booked:", 2), ("confirmation", 1),
        ]
        for (kw, weight) in keywords {
            if combined.contains(kw) { score += weight }
        }

        // Common airline names and 2-letter codes.
        let airlines: Set<String> = [
            "united", "delta", "american airlines", "lufthansa", "ryanair",
            "easyjet", "british airways", "air france", "klm", "qatar",
            "emirates", "etihad", "singapore airlines", "ana", "jal",
            "swiss", "iberia", "tap", "norwegian", "vueling", "wizz air",
            "turkish airlines", "alaska airlines", "jetblue", "frontier",
            "air canada", "lan", "latam", "air india", "indigo", "spicejet",
            "vietjet", "cathay", "korean air", "asiana", "china eastern",
            "china southern", "air china", "saudia", "vistara", "akasa",
        ]
        for name in airlines where combined.contains(name) {
            score += 4
        }

        // Three-letter uppercase IATA airport code in title (e.g. "SFO → NRT").
        if title.range(of: #"\b[A-Z]{3}\b"#, options: .regularExpression) != nil {
            score += 3
        }

        // All-day events with a location set are very travel-flavoured.
        if event.isAllDay && !location.isEmpty {
            score += 1
        }

        guard score > 0 else { return nil }

        let destination = extractDestination(
            title: title, location: location)
        return (
            score,
            DetectedTrip(
                destination: destination,
                date: event.startDate,
                sourceTitle: title
            )
        )
    }

    /// Cached set of known place names (countries + capitals + major cities)
    /// for fast O(1) destination validation.
    private static let knownPlaceNamesLowercased: Set<String> = {
        Set(
            Countries.all
                .flatMap(\.allPlaceNames)
                .map { $0.lowercased() }
        )
    }()

    /// Pull a human-readable destination out of the event's title or
    /// location. Order:
    ///   1. Known city/country name found ANYWHERE in title/location
    ///   2. `to <City>` / `→ <City>` patterns in the title
    ///   3. Comma-separated location parts, preferring the city/country part
    ///   4. Truncated title fallback
    private func extractDestination(title: String, location: String) -> String {
        // 1. Match known place names first — most reliable. Iterate over the
        //    full list; longer names (e.g. "United Arab Emirates") have to be
        //    tried before shorter ones to avoid matching "United" only.
        let sortedCountries = Countries.all.sorted { lhs, rhs in
            lhs.allPlaceNames.map(\.count).max() ?? 0
                > rhs.allPlaceNames.map(\.count).max() ?? 0
        }
        for country in sortedCountries {
            for name in country.allPlaceNames.sorted(by: { $0.count > $1.count }) {
                if title.localizedCaseInsensitiveContains(name)
                    || location.localizedCaseInsensitiveContains(name)
                {
                    return name
                }
            }
        }

        // 2. "Flight to <Dest>" / "Trip to <Dest>" / "to <Dest>" patterns.
        let toPattern = #"(?i)\bto\s+([A-Z][A-Za-zÀ-ÿ' -]{1,40})"#
        if let match = title.range(of: toPattern, options: .regularExpression)
        {
            let captured =
                String(title[match])
                .replacingOccurrences(
                    of: #"(?i)^to\s+"#, with: "",
                    options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !captured.isEmpty {
                return cleanDestination(captured)
            }
        }

        // "→ <Dest>" / "-> <Dest>"
        let arrowPattern = #"(?:→|->)\s*([A-Za-zÀ-ÿ' -]{2,40})"#
        if let match = title.range(of: arrowPattern, options: .regularExpression)
        {
            let captured =
                String(title[match])
                .replacingOccurrences(
                    of: #"^[^A-Za-z]+"#, with: "",
                    options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !captured.isEmpty {
                return cleanDestination(captured)
            }
        }

        // 3. Location with commas: try every comma-separated part and pick
        //    the first one that looks like a real place name rather than a
        //    venue. Skip parts that look like accommodation venues.
        if !location.isEmpty {
            let parts =
                location
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            // Prefer parts that match known cities/countries.
            for part in parts {
                if Self.knownPlaceNamesLowercased.contains(part.lowercased()) {
                    return part
                }
            }

            // Fall back to skipping the first part (often the venue) if
            // there's a second comma-separated part available.
            if parts.count >= 2 {
                return cleanDestination(parts[1])
            }
            if let only = parts.first {
                return cleanDestination(only)
            }
        }

        // 4. Last resort: short title.
        let trimmed =
            title
            .replacingOccurrences(
                of: #"(?i)flight\s*:?\s*"#, with: "",
                options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanDestination(trimmed.isEmpty ? title : trimmed)
    }

    private func cleanDestination(_ s: String) -> String {
        let stripped =
            s
            .components(separatedBy: CharacterSet(charactersIn: "(/|·:"))
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? s
        // Cap length so the wallpaper still fits.
        if stripped.count > 30 {
            return String(stripped.prefix(30)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return stripped
    }
}
