import LifeInWeeksCore
import SwiftUI

struct CountryPickerView: View {
    @Binding var selection: Set<String>
    let style: ThemeStyle
    let onClose: () -> Void

    @State private var query: String = ""
    @State private var activeRegion: Country.Region? = nil

    private var filtered: [Country] {
        var list = Countries.all
        if let activeRegion {
            list = list.filter { $0.region == activeRegion }
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let q = trimmed.lowercased()
            list = list.filter {
                $0.name.lowercased().contains(q)
                    || $0.code.lowercased().contains(q)
            }
        }
        return list
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: style.background,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                searchBar
                regionFilter
                Divider().opacity(0.25)
                list
                Divider().opacity(0.25)
                footer
            }
        }
        .frame(width: 560, height: 680)
        .foregroundStyle(style.foreground)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Countries visited")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text("\(selection.count) of \(Countries.totalCount)")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(style.foreground.opacity(0.65))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: selection.count)
            }

            Spacer()

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(style.foreground.opacity(0.45))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 14)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(style.foreground.opacity(0.55))
            TextField("Search countries", text: $query)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .rounded))
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(style.foreground.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(style.foreground.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(style.foreground.opacity(0.10), lineWidth: 1)
        )
        .padding(.horizontal, 22)
        .padding(.bottom, 12)
    }

    private var regionFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                RegionChip(
                    label: "All",
                    isActive: activeRegion == nil,
                    style: style
                ) {
                    activeRegion = nil
                }
                ForEach(Country.Region.allCases, id: \.id) { region in
                    RegionChip(
                        label: region.rawValue,
                        isActive: activeRegion == region,
                        style: style
                    ) {
                        activeRegion = activeRegion == region ? nil : region
                    }
                }
            }
            .padding(.horizontal, 22)
        }
        .padding(.bottom, 12)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if filtered.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.title)
                            .foregroundStyle(style.foreground.opacity(0.4))
                        Text("No matches")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(style.foreground.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ForEach(filtered) { country in
                        CountryRow(
                            country: country,
                            isSelected: selection.contains(country.code),
                            style: style
                        ) {
                            toggle(country)
                        }
                        if country.id != filtered.last?.id {
                            Divider()
                                .padding(.leading, 56)
                                .opacity(0.15)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack {
            Button("Clear all") {
                selection.removeAll()
            }
            .buttonStyle(.plain)
            .font(.system(.callout, design: .rounded))
            .foregroundStyle(style.foreground.opacity(0.65))
            .disabled(selection.isEmpty)

            Spacer()

            Button {
                onClose()
            } label: {
                Text("Done")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(style.accent.opacity(0.85))
                    )
                    .foregroundStyle(style.isLight ? .white : style.foreground)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private func toggle(_ country: Country) {
        if selection.contains(country.code) {
            selection.remove(country.code)
        } else {
            selection.insert(country.code)
        }
    }
}

private struct CountryRow: View {
    let country: Country
    let isSelected: Bool
    let style: ThemeStyle
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(country.flag)
                    .font(.system(size: 24))
                    .frame(width: 32, alignment: .center)

                VStack(alignment: .leading, spacing: 1) {
                    Text(country.name)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundStyle(style.foreground)
                    Text(country.region.rawValue)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(style.foreground.opacity(0.5))
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(
                            isSelected
                                ? style.accent : style.foreground.opacity(0.25),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(style.accent)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(style.isLight ? .white : style.foreground)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 9)
            .background(
                isHovered ? style.foreground.opacity(0.05) : .clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

private struct RegionChip: View {
    let label: String
    let isActive: Bool
    let style: ThemeStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.callout, design: .rounded).weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(
                            isActive
                                ? style.accent.opacity(0.85)
                                : style.foreground.opacity(0.08)
                        )
                )
                .overlay(
                    Capsule().stroke(
                        isActive
                            ? style.accent
                            : style.foreground.opacity(0.12),
                        lineWidth: 1
                    )
                )
                .foregroundStyle(
                    isActive
                        ? (style.isLight ? .white : style.foreground)
                        : style.foreground.opacity(0.8)
                )
        }
        .buttonStyle(.plain)
    }
}
