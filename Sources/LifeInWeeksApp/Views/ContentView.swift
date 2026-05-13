import LifeInWeeksCore
import SwiftUI

struct ContentView: View {
    @ObservedObject var preferences: PreferencesModel

    var body: some View {
        let style = preferences.settings.activePreset.theme.style

        ZStack {
            AtmosphericBackground(style: style)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    HStack {
                        Spacer()
                        SaveBadge(preferences: preferences, style: style)
                    }
                    .padding(.bottom, -16)

                    AppHeader(style: style)

                    WallpaperPreviewCard(preferences: preferences, style: style)

                    WallpaperStyleField(
                        selection: wallpaperStyleBinding,
                        style: style
                    )

                    TitleField(text: titleBinding, style: style)

                    BirthDateField(
                        date: birthDateBinding,
                        style: style
                    )

                    LifeSpanField(
                        years: lifeExpectancyBinding,
                        style: style
                    )

                    AboutYouField(
                        countries: countryCodesBinding,
                        destination: destinationBinding,
                        autoDetect: autoDetectBinding,
                        enabledCalendarIDs: enabledCalendarIDsBinding,
                        detector: preferences.travelDetector,
                        hobby: hobbyBinding,
                        learning: learningBinding,
                        style: style,
                        onRefresh: {
                            Task { await preferences.refreshTravelDetectorIfNeeded() }
                        }
                    )

                    ThemeField(
                        availableThemes: preferences.settings.wallpaperStyle.availableThemes,
                        mode: themeModeBinding,
                        customSelection: themeBinding,
                        daySelection: dayThemeBinding,
                        nightSelection: nightThemeBinding,
                        style: style
                    )

                    LayoutField(
                        titlePos: blockPositionBinding(.title),
                        factsPos: blockPositionBinding(.facts),
                        gridPos: blockPositionBinding(.grid),
                        footerPos: blockPositionBinding(.footer),
                        onReset: {
                            let defaults = StylePreset.defaultPositions(
                                for: preferences.settings.wallpaperStyle)
                            preferences.settings.updateActivePreset { preset in
                                preset.positions = defaults
                            }
                        },
                        style: style
                    )

                    WallpaperToggleField(
                        enabled: wallpaperEnabledBinding,
                        opacity: wallpaperOpacityBinding,
                        backdropOpacity: backdropOpacityBinding,
                        style: style
                    )
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 36)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(style.foreground)
    }

    private var birthDateBinding: Binding<Date> {
        Binding {
            preferences.settings.birthDate ?? defaultBirthDate
        } set: { newValue in
            preferences.settings.birthDate = newValue
        }
    }

    private var lifeExpectancyBinding: Binding<Double> {
        Binding {
            Double(preferences.settings.normalizedLifeExpectancyYears)
        } set: { newValue in
            preferences.settings.lifeExpectancyYears = Int(newValue.rounded())
        }
    }

    private var themeBinding: Binding<CalendarTheme> {
        Binding {
            preferences.settings.theme
        } set: { newValue in
            preferences.settings.theme = newValue
        }
    }

    private var themeModeBinding: Binding<ThemeMode> {
        Binding {
            preferences.settings.themeMode
        } set: { newValue in
            preferences.settings.themeMode = newValue
        }
    }

    private var dayThemeBinding: Binding<CalendarTheme> {
        Binding {
            preferences.settings.dayTheme
        } set: { newValue in
            preferences.settings.dayTheme = newValue
        }
    }

    private var nightThemeBinding: Binding<CalendarTheme> {
        Binding {
            preferences.settings.nightTheme
        } set: { newValue in
            preferences.settings.nightTheme = newValue
        }
    }

    private var wallpaperEnabledBinding: Binding<Bool> {
        Binding {
            preferences.settings.wallpaperEnabled
        } set: { newValue in
            preferences.settings.wallpaperEnabled = newValue
        }
    }

    private var wallpaperOpacityBinding: Binding<Double> {
        Binding {
            preferences.settings.normalizedWallpaperOpacity
        } set: { newValue in
            preferences.settings.wallpaperOpacity = newValue
        }
    }

    private var backdropOpacityBinding: Binding<Double> {
        Binding {
            preferences.settings.normalizedBackdropOpacity
        } set: { newValue in
            preferences.settings.backdropOpacity = newValue
        }
    }

    private var countryCodesBinding: Binding<Set<String>> {
        Binding {
            preferences.settings.visitedCountryCodes
        } set: { newValue in
            preferences.settings.visitedCountryCodes = newValue
        }
    }

    private var destinationBinding: Binding<String> {
        Binding {
            preferences.settings.nextDestination
        } set: { newValue in
            preferences.settings.nextDestination = newValue
        }
    }

    private var autoDetectBinding: Binding<Bool> {
        Binding {
            preferences.settings.autoDetectNextDestination
        } set: { newValue in
            preferences.settings.autoDetectNextDestination = newValue
        }
    }

    private var wallpaperStyleBinding: Binding<WallpaperStyle> {
        Binding {
            preferences.settings.wallpaperStyle
        } set: { newValue in
            preferences.settings.wallpaperStyle = newValue
        }
    }

    private func blockPositionBinding(_ block: BlockID) -> Binding<BlockPosition> {
        Binding {
            preferences.settings.position(for: block)
        } set: { newValue in
            preferences.settings.updateActivePreset { preset in
                preset.setPosition(newValue, for: block)
            }
        }
    }

    private var enabledCalendarIDsBinding: Binding<Set<String>> {
        Binding {
            preferences.settings.enabledCalendarIdentifiers
        } set: { newValue in
            preferences.settings.enabledCalendarIdentifiers = newValue
        }
    }

    private var hobbyBinding: Binding<String> {
        Binding {
            preferences.settings.currentHobby
        } set: { newValue in
            preferences.settings.currentHobby = newValue
        }
    }

    private var learningBinding: Binding<String> {
        Binding {
            preferences.settings.currentlyLearning
        } set: { newValue in
            preferences.settings.currentlyLearning = newValue
        }
    }

    private var titleBinding: Binding<String> {
        Binding {
            preferences.settings.wallpaperTitle
        } set: { newValue in
            preferences.settings.wallpaperTitle = newValue
        }
    }

    private var defaultBirthDate: Date {
        Calendar.current.date(from: DateComponents(year: 1995, month: 1, day: 1)) ?? Date()
    }
}

private struct AtmosphericBackground: View {
    let style: ThemeStyle

    var body: some View {
        LinearGradient(
            colors: style.background,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            ZStack {
                Circle()
                    .fill(style.accent.opacity(style.isLight ? 0.18 : 0.24))
                    .frame(width: 460, height: 460)
                    .blur(radius: 120)
                    .offset(x: -320, y: -240)

                Circle()
                    .fill(
                        (style.isLight ? Color.black : Color.white)
                            .opacity(style.isLight ? 0.05 : 0.10)
                    )
                    .frame(width: 480, height: 480)
                    .blur(radius: 160)
                    .offset(x: 320, y: 280)
            }
        }
        .ignoresSafeArea()
    }
}

private struct SaveBadge: View {
    @ObservedObject var preferences: PreferencesModel
    let style: ThemeStyle

    @State private var isSaving = false

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                if isSaving {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(style.accent)
                        .transition(.opacity.combined(with: .scale))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.green)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(width: 12, height: 12)

            Text(isSaving ? "Saving…" : "All changes saved")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(style.foreground.opacity(0.7))
                .contentTransition(.opacity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(style.foreground.opacity(0.15), lineWidth: 1))
        .onChange(of: preferences.settings) { _ in
            withAnimation(.snappy(duration: 0.15)) {
                isSaving = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.snappy(duration: 0.2)) {
                    isSaving = false
                }
            }
        }
        .help("Your changes are saved automatically.")
    }
}

private struct AppHeader: View {
    let style: ThemeStyle

    var body: some View {
        VStack(spacing: 6) {
            Text("Life in Weeks")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .tracking(-1.5)
            Text("Your life as a desktop wallpaper")
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(style.foreground.opacity(0.65))
        }
        .padding(.top, 8)
    }
}

private struct WallpaperPreviewCard: View {
    @ObservedObject var preferences: PreferencesModel
    let style: ThemeStyle

    var body: some View {
        WallpaperView(preferences: preferences)
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(style.foreground.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: .black.opacity(style.isLight ? 0.10 : 0.30), radius: 24, x: 0, y: 12)
    }
}

private struct FieldShell<Content: View>: View {
    let title: String
    let icon: String
    let style: ThemeStyle
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(style.accent)
                Text(title)
                    .font(.system(.headline, design: .rounded))
            }
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(style.foreground.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct TitleField: View {
    @Binding var text: String
    let style: ThemeStyle

    var body: some View {
        FieldShell(title: "Wallpaper title", icon: "textformat", style: style) {
            TextField("Life in Weeks", text: $text)
                .textFieldStyle(.plain)
                .font(.system(.title3, design: .rounded).weight(.medium))
                .foregroundStyle(style.foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(style.foreground.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(style.foreground.opacity(0.12), lineWidth: 1)
                )
        }
    }
}

private struct BirthDateField: View {
    @Binding var date: Date
    let style: ThemeStyle

    @State private var isOpen = false

    var body: some View {
        FieldShell(title: "Born", icon: "calendar", style: style) {
            HStack {
                Text(date, format: .dateTime.day().month(.wide).year())
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundStyle(style.foreground)

                Spacer()

                Button {
                    isOpen.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        Text(isOpen ? "Done" : "Change")
                    }
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(style.accent.opacity(0.18), in: Capsule())
                    .overlay(Capsule().stroke(style.accent.opacity(0.5), lineWidth: 1))
                    .foregroundStyle(style.foreground)
                }
                .buttonStyle(.plain)
            }

            if isOpen {
                DatePicker(
                    "",
                    selection: $date,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(style.accent)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.snappy(duration: 0.25), value: isOpen)
    }
}

private struct LifeSpanField: View {
    @Binding var years: Double
    let style: ThemeStyle

    private let range: ClosedRange<Double> = Double(LifeCalendarSettings.minimumLifeExpectancyYears)...Double(LifeCalendarSettings.maximumLifeExpectancyYears)

    var body: some View {
        FieldShell(title: "Live to", icon: "infinity", style: style) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(Int(years.rounded()))")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("years")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(style.foreground.opacity(0.65))
                Spacer()
            }

            Slider(
                value: $years,
                in: range,
                step: 1
            ) {
                Text("Life span")
            } minimumValueLabel: {
                Text("\(Int(range.lowerBound))")
                    .font(.caption)
                    .foregroundStyle(style.foreground.opacity(0.55))
            } maximumValueLabel: {
                Text("\(Int(range.upperBound))")
                    .font(.caption)
                    .foregroundStyle(style.foreground.opacity(0.55))
            }
            .tint(style.accent)
        }
    }
}

private struct AboutYouField: View {
    @Binding var countries: Set<String>
    @Binding var destination: String
    @Binding var autoDetect: Bool
    @Binding var enabledCalendarIDs: Set<String>
    @ObservedObject var detector: CalendarTravelDetector
    @Binding var hobby: String
    @Binding var learning: String
    let style: ThemeStyle
    let onRefresh: () -> Void

    var body: some View {
        FieldShell(title: "About you", icon: "sparkles", style: style) {
            VStack(alignment: .leading, spacing: 18) {
                CountriesPickerRow(selection: $countries, style: style)
                NextDestinationRow(
                    destination: $destination,
                    autoDetect: $autoDetect,
                    enabledCalendarIDs: $enabledCalendarIDs,
                    detector: detector,
                    style: style,
                    onRefresh: onRefresh
                )
                LabeledInput(
                    label: "Current hobby",
                    placeholder: "What are you into this season?",
                    icon: "sparkles",
                    text: $hobby,
                    style: style
                )
                LabeledInput(
                    label: "Currently learning",
                    placeholder: "A language, instrument, skill…",
                    icon: "character.bubble",
                    text: $learning,
                    style: style
                )
            }
        }
    }
}

private struct NextDestinationRow: View {
    @Binding var destination: String
    @Binding var autoDetect: Bool
    @Binding var enabledCalendarIDs: Set<String>
    @ObservedObject var detector: CalendarTravelDetector
    let style: ThemeStyle
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "airplane")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(style.accent)
                Text("Next destination")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(style.foreground.opacity(0.7))
                    .tracking(0.5)
                Spacer()
                Toggle("Auto-detect from Calendar", isOn: $autoDetect)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .tint(style.accent)
                Text("From Calendar")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(style.foreground.opacity(0.6))
            }

            if autoDetect {
                AutoDetectStatus(
                    detector: detector,
                    enabledCalendarIDs: $enabledCalendarIDs,
                    style: style,
                    onRefresh: onRefresh
                )
            } else {
                TextField("Where to next?", text: $destination)
                    .textFieldStyle(.plain)
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundStyle(style.foreground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(style.foreground.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(style.foreground.opacity(0.12), lineWidth: 1)
                    )
            }
        }
    }
}

private struct AutoDetectStatus: View {
    @ObservedObject var detector: CalendarTravelDetector
    @Binding var enabledCalendarIDs: Set<String>
    let style: ThemeStyle
    let onRefresh: () -> Void

    @State private var isShowingCalendarPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                statusIcon
                VStack(alignment: .leading, spacing: 2) {
                    Text(primaryText)
                        .font(.system(.callout, design: .rounded).weight(.medium))
                        .foregroundStyle(style.foreground)
                    if let secondary = secondaryText {
                        Text(secondary)
                            .font(.caption)
                            .foregroundStyle(style.foreground.opacity(0.6))
                    }
                }
                Spacer()
                actionButton
            }

            if detector.accessState == .authorized {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(style.foreground.opacity(0.55))
                    Text(calendarFilterSummary)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(style.foreground.opacity(0.65))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Button {
                        detector.refreshAvailableCalendars()
                        isShowingCalendarPicker = true
                    } label: {
                        Text("Choose")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(style.accent.opacity(0.18), in: Capsule())
                            .overlay(
                                Capsule().stroke(style.accent.opacity(0.45), lineWidth: 1)
                            )
                            .foregroundStyle(style.foreground)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isShowingCalendarPicker) {
                        CalendarFilterPopover(
                            calendars: detector.availableCalendars,
                            selection: $enabledCalendarIDs,
                            style: style,
                            onClose: {
                                isShowingCalendarPicker = false
                                onRefresh()
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(style.foreground.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(style.foreground.opacity(0.12), lineWidth: 1)
        )
    }

    private var calendarFilterSummary: String {
        if enabledCalendarIDs.isEmpty {
            let count = detector.availableCalendars.count
            return count == 0
                ? "All calendars"
                : "All calendars (\(count))"
        }
        if enabledCalendarIDs.count == 1,
            let id = enabledCalendarIDs.first,
            let cal = detector.availableCalendars.first(where: { $0.id == id })
        {
            return "\(cal.title) · \(cal.sourceTitle)"
        }
        return "\(enabledCalendarIDs.count) of \(detector.availableCalendars.count) calendars"
    }

    private var statusIcon: some View {
        Group {
            switch detector.accessState {
            case .notDetermined:
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(style.foreground.opacity(0.5))
            case .denied:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            case .authorized:
                Image(systemName: detector.detectedTrip != nil ? "airplane.circle.fill" : "magnifyingglass")
                    .foregroundStyle(style.accent)
            }
        }
        .font(.system(size: 18, weight: .semibold))
        .frame(width: 22)
    }

    private var primaryText: String {
        switch detector.accessState {
        case .notDetermined:
            return "Calendar access needed"
        case .denied:
            return "Calendar access denied"
        case .authorized:
            if let trip = detector.detectedTrip {
                return trip.destination
            }
            return "No upcoming trips found"
        }
    }

    private var secondaryText: String? {
        switch detector.accessState {
        case .notDetermined:
            return "Grant access to detect flights"
        case .denied:
            return "Enable in System Settings → Privacy & Security → Calendars"
        case .authorized:
            if let trip = detector.detectedTrip {
                return "On \(Formatters.compactDate.string(from: trip.date)) · from your calendar"
            }
            return "Will keep watching every 15 minutes"
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch detector.accessState {
        case .notDetermined:
            Button("Grant access") {
                Task { _ = await detector.requestAccess() }
            }
            .buttonStyle(.plain)
            .font(.system(.callout, design: .rounded).weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(style.accent.opacity(0.18), in: Capsule())
            .overlay(Capsule().stroke(style.accent.opacity(0.5), lineWidth: 1))
            .foregroundStyle(style.foreground)
        case .denied:
            Button("Open Settings") {
                if let url = URL(
                    string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
                ) {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.plain)
            .font(.system(.callout, design: .rounded).weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.18), in: Capsule())
            .overlay(Capsule().stroke(Color.orange.opacity(0.5), lineWidth: 1))
            .foregroundStyle(style.foreground)
        case .authorized:
            Button {
                Task { await detector.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(style.foreground.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Refresh now")
        }
    }
}

private struct CountriesPickerRow: View {
    @Binding var selection: Set<String>
    let style: ThemeStyle

    @State private var isShowingPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "globe.europe.africa")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(style.accent)
                Text("Countries visited")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(style.foreground.opacity(0.7))
                    .tracking(0.5)
            }

            HStack(alignment: .center, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(selection.count)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(style.foreground)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: selection.count)
                    Text("of \(Countries.totalCount)")
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(style.foreground.opacity(0.55))
                }

                Spacer()

                Button {
                    isShowingPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checklist")
                        Text("Choose")
                    }
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(style.accent.opacity(0.18), in: Capsule())
                    .overlay(Capsule().stroke(style.accent.opacity(0.5), lineWidth: 1))
                    .foregroundStyle(style.foreground)
                }
                .buttonStyle(.plain)
            }

            if !selection.isEmpty {
                FlagPreviewStrip(selection: selection)
            }
        }
        .sheet(isPresented: $isShowingPicker) {
            CountryPickerView(
                selection: $selection,
                style: style,
                onClose: { isShowingPicker = false }
            )
        }
    }
}

private struct FlagPreviewStrip: View {
    let selection: Set<String>

    private var flags: [Country] {
        Countries.all.filter { selection.contains($0.code) }
    }

    var body: some View {
        let maxVisible = 16
        let visible = Array(flags.prefix(maxVisible))
        let overflow = flags.count - visible.count

        HStack(spacing: 4) {
            ForEach(visible) { country in
                Text(country.flag)
                    .font(.system(size: 16))
                    .lineLimit(1)
                    .fixedSize()
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
                    .lineLimit(1)
                    .fixedSize()
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }
}

private struct LabeledInput: View {
    let label: String
    let placeholder: String
    let icon: String
    @Binding var text: String
    let style: ThemeStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(style.accent)
                Text(label)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(style.foreground.opacity(0.7))
                    .tracking(0.5)
            }
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(.title3, design: .rounded).weight(.medium))
                .foregroundStyle(style.foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(style.foreground.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(style.foreground.opacity(0.12), lineWidth: 1)
                )
        }
    }
}

private struct CalendarFilterPopover: View {
    let calendars: [CalendarTravelDetector.CalendarOption]
    @Binding var selection: Set<String>
    let style: ThemeStyle
    let onClose: () -> Void

    private var grouped: [(source: String, items: [CalendarTravelDetector.CalendarOption])] {
        let bySource = Dictionary(grouping: calendars, by: { $0.sourceTitle })
        return
            bySource
            .map { (source: $0.key, items: $0.value) }
            .sorted { $0.source < $1.source }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Calendars")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Button("All") {
                    selection.removeAll()
                }
                .buttonStyle(.plain)
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(style.foreground.opacity(0.7))
                Button("None") {
                    selection = []
                    // Mark none-state explicitly with a sentinel so detection
                    // doesn't fall back to "all". We achieve this by storing
                    // a non-existent id.
                    selection = ["__none__"]
                }
                .buttonStyle(.plain)
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(style.foreground.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if calendars.isEmpty {
                        Text("No calendars found.")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(grouped, id: \.source) { group in
                            Section {
                                ForEach(group.items) { cal in
                                    CalendarRow(
                                        calendar: cal,
                                        isOn: bindingFor(cal),
                                        style: style
                                    )
                                }
                            } header: {
                                Text(group.source.uppercased())
                                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                                    .tracking(1.4)
                                    .foregroundStyle(style.foreground.opacity(0.55))
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") {
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(style.accent)
            }
            .padding(12)
        }
        .frame(width: 360, height: 420)
    }

    private func bindingFor(_ cal: CalendarTravelDetector.CalendarOption) -> Binding<Bool> {
        Binding {
            // Empty set == "all selected" semantic. So if empty, treat as on.
            if selection.isEmpty { return true }
            return selection.contains(cal.id)
        } set: { newValue in
            // First explicit toggle on an empty set: switch to "explicit"
            // mode and start with everything ticked, then flip the requested
            // one.
            if selection.isEmpty {
                selection = Set(calendars.map(\.id))
            }
            // Drop the sentinel if present.
            selection.remove("__none__")
            if newValue {
                selection.insert(cal.id)
            } else {
                selection.remove(cal.id)
            }
        }
    }
}

private struct CalendarRow: View {
    let calendar: CalendarTravelDetector.CalendarOption
    @Binding var isOn: Bool
    let style: ThemeStyle

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                if let cg = calendar.cgColor {
                    Circle()
                        .fill(Color(cgColor: cg))
                        .frame(width: 10, height: 10)
                } else {
                    Circle()
                        .fill(style.accent)
                        .frame(width: 10, height: 10)
                }
                Text(calendar.title)
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(style.foreground)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            isOn ? style.accent : style.foreground.opacity(0.3),
                            lineWidth: 1.5
                        )
                        .frame(width: 18, height: 18)
                    if isOn {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(style.accent)
                            .frame(width: 18, height: 18)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(style.isLight ? .white : style.foreground)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct WallpaperStyleField: View {
    @Binding var selection: WallpaperStyle
    let style: ThemeStyle

    var body: some View {
        FieldShell(title: "Wallpaper style", icon: "rectangle.on.rectangle.angled", style: style) {
            VStack(spacing: 10) {
                ForEach(WallpaperStyle.allCases) { wpStyle in
                    WallpaperStyleCard(
                        wpStyle: wpStyle,
                        isSelected: selection == wpStyle,
                        accent: style.accent
                    ) {
                        withAnimation(.snappy(duration: 0.2)) {
                            selection = wpStyle
                        }
                    }
                }
            }
        }
    }
}

private struct WallpaperStyleCard: View {
    let wpStyle: WallpaperStyle
    let isSelected: Bool
    let accent: Color
    let onTap: () -> Void

    var body: some View {
        let themeStyle = wpStyle.defaultTheme.style

        Button(action: onTap) {
            HStack(spacing: 14) {
                styleThumbnail(themeStyle: themeStyle)
                    .frame(width: 96, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? accent : Color.primary.opacity(0.10),
                                    lineWidth: isSelected ? 2 : 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(wpStyle.title)
                        .font(.system(.headline, design: .rounded))
                    Text(wpStyle.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? accent : Color.primary.opacity(0.25),
                                lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(accent).frame(width: 14, height: 14)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.10) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? accent.opacity(0.45) : Color.primary.opacity(0.08),
                            lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func styleThumbnail(themeStyle: ThemeStyle) -> some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: themeStyle.background,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            switch wpStyle {
            case .classic:
                // L-shape: title left, mini grid right
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 3) {
                        Rectangle().fill(themeStyle.foreground).frame(width: 18, height: 4)
                        Rectangle().fill(themeStyle.foreground.opacity(0.5)).frame(width: 12, height: 3)
                        Rectangle().fill(themeStyle.foreground).frame(width: 18, height: 4)
                        Spacer(minLength: 0)
                    }
                    miniGridSwatch(themeStyle: themeStyle)
                }
                .padding(8)
            case .editorial:
                // Centered big title, grid below
                VStack(spacing: 4) {
                    Rectangle().fill(themeStyle.foreground).frame(width: 50, height: 6)
                    miniGridSwatch(themeStyle: themeStyle)
                        .frame(height: 20)
                    Rectangle().fill(themeStyle.foreground.opacity(0.5)).frame(width: 40, height: 2)
                }
                .padding(8)
            case .minimal:
                // Centered narrow column
                VStack(spacing: 5) {
                    Rectangle().fill(themeStyle.foreground).frame(width: 40, height: 4)
                    HStack(spacing: 1) {
                        ForEach(0..<24, id: \.self) { _ in
                            Rectangle().fill(themeStyle.lived.first ?? themeStyle.foreground)
                                .frame(width: 1.5, height: 8)
                        }
                    }
                    Rectangle().fill(themeStyle.foreground.opacity(0.4)).frame(width: 30, height: 2)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func miniGridSwatch(themeStyle: ThemeStyle) -> some View {
        VStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<10, id: \.self) { col in
                        let isLived = row >= 2 || (row == 2 && col < 4)
                        Rectangle()
                            .fill(
                                isLived
                                    ? (themeStyle.lived.first ?? themeStyle.foreground)
                                    : themeStyle.future
                            )
                            .frame(width: 2.5, height: 2.5)
                    }
                }
            }
        }
    }
}

private struct ThemeField: View {
    let availableThemes: [CalendarTheme]
    @Binding var mode: ThemeMode
    @Binding var customSelection: CalendarTheme
    @Binding var daySelection: CalendarTheme
    @Binding var nightSelection: CalendarTheme
    let style: ThemeStyle

    var body: some View {
        FieldShell(title: "Theme", icon: "paintpalette", style: style) {
            VStack(alignment: .leading, spacing: 14) {
                Picker("", selection: $mode) {
                    Text("Custom").tag(ThemeMode.custom)
                    Text("System").tag(ThemeMode.system)
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if mode == .custom {
                    ThemeSwatchGrid(
                        themes: availableThemes,
                        selection: $customSelection,
                        accent: style.accent
                    )
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ThemeSubsectionLabel(
                            icon: "sun.max.fill",
                            text: "Day theme",
                            style: style
                        )
                        ThemeSwatchGrid(
                            themes: availableThemes,
                            selection: $daySelection,
                            accent: style.accent
                        )

                        ThemeSubsectionLabel(
                            icon: "moon.stars.fill",
                            text: "Night theme",
                            style: style
                        )
                        ThemeSwatchGrid(
                            themes: availableThemes,
                            selection: $nightSelection,
                            accent: style.accent
                        )

                        Text("Auto-switches with macOS Appearance.")
                            .font(.caption)
                            .foregroundStyle(style.foreground.opacity(0.55))
                    }
                    .transition(.opacity)
                }
            }
            .animation(.snappy(duration: 0.2), value: mode)
        }
        // If the user switches wallpaper style and their saved themes
        // aren't in the new style's list, snap to defaults silently.
        .onChange(of: availableThemes) { _ in
            sanitizeSelections()
        }
        .onAppear { sanitizeSelections() }
    }

    private func sanitizeSelections() {
        if !availableThemes.contains(customSelection) {
            customSelection = availableThemes.first ?? customSelection
        }
        if !availableThemes.contains(daySelection) {
            daySelection = availableThemes.first { $0.style.isLight } ?? availableThemes.first ?? daySelection
        }
        if !availableThemes.contains(nightSelection) {
            nightSelection = availableThemes.first { !$0.style.isLight } ?? availableThemes.first ?? nightSelection
        }
    }
}

private struct ThemeSubsectionLabel: View {
    let icon: String
    let text: String
    let style: ThemeStyle

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(style.accent)
            Text(text)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(style.foreground.opacity(0.7))
                .tracking(0.5)
        }
    }
}

private struct ThemeSwatchGrid: View {
    let themes: [CalendarTheme]
    @Binding var selection: CalendarTheme
    let accent: Color

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
            spacing: 10
        ) {
            ForEach(themes) { theme in
                ThemeSwatch(
                    theme: theme,
                    isSelected: selection == theme,
                    accent: accent
                ) {
                    selection = theme
                }
            }
        }
    }
}

private struct ThemeSwatch: View {
    let theme: CalendarTheme
    let isSelected: Bool
    let accent: Color
    let onTap: () -> Void

    var body: some View {
        let s = theme.style

        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    LinearGradient(
                        colors: s.background,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    HStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: s.lived, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 12, height: 12)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: s.current, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 12, height: 12)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(s.future)
                            .frame(width: 12, height: 12)
                    }
                }
                .frame(height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? accent : Color.primary.opacity(0.12),
                                lineWidth: isSelected ? 2.5 : 1)
                )

                Text(theme.title)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(s.foreground.opacity(isSelected ? 1.0 : 0.7))
            }
        }
        .buttonStyle(.plain)
        .help(theme.subtitle)
    }
}

private struct LayoutField: View {
    @Binding var titlePos: BlockPosition
    @Binding var factsPos: BlockPosition
    @Binding var gridPos: BlockPosition
    @Binding var footerPos: BlockPosition
    let onReset: () -> Void
    let style: ThemeStyle

    var body: some View {
        FieldShell(
            title: "Layout",
            icon: "square.split.bottomrightquarter",
            style: style
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(
                    "Drag each block horizontally and vertically. Positions are saved per wallpaper style."
                )
                .font(.caption)
                .foregroundStyle(style.foreground.opacity(0.6))

                BlockLayoutControl(
                    block: .title,
                    position: $titlePos,
                    style: style
                )
                BlockLayoutControl(
                    block: .facts,
                    position: $factsPos,
                    style: style
                )
                BlockLayoutControl(
                    block: .grid,
                    position: $gridPos,
                    style: style
                )
                BlockLayoutControl(
                    block: .footer,
                    position: $footerPos,
                    style: style
                )

                HStack {
                    Spacer()
                    Button("Reset to default", action: onReset)
                        .buttonStyle(.plain)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(style.foreground.opacity(0.6))
                }
                .padding(.top, 2)
            }
        }
    }
}

private struct BlockLayoutControl: View {
    let block: BlockID
    @Binding var position: BlockPosition
    let style: ThemeStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: block.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(style.accent)
                Text(block.displayName)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .foregroundStyle(style.foreground)
                Spacer()
                Text("\(Int((position.x * 100).rounded()))%, \(Int((position.y * 100).rounded()))%")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(style.foreground.opacity(0.55))
                    .monospacedDigit()
            }

            HStack(spacing: 12) {
                AxisSlider(
                    axis: .horizontal,
                    value: Binding(
                        get: { position.x },
                        set: { position.x = $0 }
                    ),
                    style: style
                )
                AxisSlider(
                    axis: .vertical,
                    value: Binding(
                        get: { position.y },
                        set: { position.y = $0 }
                    ),
                    style: style
                )
            }
        }
        .padding(.vertical, 4)
    }
}

private enum LayoutAxis {
    case horizontal, vertical

    var icon: String {
        switch self {
        case .horizontal: return "arrow.left.and.right"
        case .vertical: return "arrow.up.and.down"
        }
    }

    var label: String {
        switch self {
        case .horizontal: return "X"
        case .vertical: return "Y"
        }
    }
}

private struct AxisSlider: View {
    let axis: LayoutAxis
    @Binding var value: Double
    let style: ThemeStyle

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: axis.icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(style.foreground.opacity(0.55))
                .frame(width: 14)
            Slider(value: $value, in: 0.0...1.0)
                .tint(style.accent)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WallpaperToggleField: View {
    @Binding var enabled: Bool
    @Binding var opacity: Double
    @Binding var backdropOpacity: Double
    let style: ThemeStyle

    var body: some View {
        FieldShell(title: "Wallpaper", icon: "photo.on.rectangle.angled", style: style) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set as desktop + lock screen")
                        .font(.system(.body, design: .rounded).weight(.medium))
                    Text("Updates automatically each week.")
                        .font(.caption)
                        .foregroundStyle(style.foreground.opacity(0.6))
                }
                Spacer()
                Toggle("", isOn: $enabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(style.accent)
            }

            if enabled {
                VStack(alignment: .leading, spacing: 16) {
                    OpacityRow(
                        label: "Wallpaper opacity",
                        value: $opacity,
                        range: 0.2...1.0,
                        format: percentFormat,
                        style: style
                    )

                    OpacityRow(
                        label: "Backdrop tint",
                        value: $backdropOpacity,
                        range: 0.0...0.15,
                        format: tenthsPercentFormat,
                        style: style,
                        helpText: "Faint typographic layer of every place you've visited."
                    )
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.snappy(duration: 0.2), value: enabled)
    }

    private func percentFormat(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    /// Backdrop is a sub-percent feel; show one decimal point so granular
    /// changes are visible to the user.
    private func tenthsPercentFormat(_ value: Double) -> String {
        let pct = value * 100
        if pct < 10 {
            return String(format: "%.1f%%", pct)
        } else {
            return "\(Int(pct.rounded()))%"
        }
    }
}

private struct OpacityRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: (Double) -> String
    let style: ThemeStyle
    var helpText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(style.foreground.opacity(0.7))
                Spacer()
                Text(format(value))
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .contentTransition(.numericText())
                    .monospacedDigit()
            }
            Slider(value: $value, in: range)
                .tint(style.accent)
            if let helpText {
                Text(helpText)
                    .font(.caption)
                    .foregroundStyle(style.foreground.opacity(0.55))
            }
        }
    }
}
