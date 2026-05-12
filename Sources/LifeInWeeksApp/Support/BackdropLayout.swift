import AppKit
import Foundation
import LifeInWeeksCore

struct PlacedWord: Hashable, Identifiable {
    let id: Int
    let text: String
    let position: CGPoint
    let fontSize: CGFloat
    let rotation: Double  // degrees, 0 for horizontal
}

enum BackdropLayout {
    /// Lays out a list of country names as a typographic poster filling the canvas.
    ///
    /// Uses a row-based greedy packing algorithm:
    /// - Decides each row's height from a weighted distribution (a few large
    ///   anchor rows, mostly medium rows, some small filler rows).
    /// - Within each row, places shuffled names left-to-right until the next
    ///   word would overflow, then drops to the next row.
    /// - Cycles through the word list if names run out before the canvas is
    ///   filled, so the canvas is always visually dense.
    static func compute(
        countries: [String],
        canvas: CGSize,
        seed: UInt64
    ) -> [PlacedWord] {
        guard !countries.isEmpty, canvas.width > 0, canvas.height > 0 else {
            return []
        }

        var rng = SeededRng(seed: seed)
        let shuffled = countries.shuffled(using: &rng)
        let totalUnique = shuffled.count

        var placed: [PlacedWord] = []
        var idCounter = 0
        var y: CGFloat = 0
        var nameCursor = 0
        var iteration = 0

        // Choose sizing scale based on how many words we have.
        // Fewer words → bigger sizes so the canvas still feels populated.
        let scale: CGFloat
        switch totalUnique {
        case 0...20: scale = 1.6
        case 21...50: scale = 1.2
        case 51...100: scale = 0.95
        default: scale = 0.8
        }

        let xlSize = canvas.height * 0.090 * scale
        let lgSize = canvas.height * 0.060 * scale
        let mdSize = canvas.height * 0.040 * scale
        let smSize = canvas.height * 0.026 * scale

        let horizontalGap: CGFloat = canvas.width * 0.020
        let lineHeightFactor: CGFloat = 1.45
        // Words within a row are allowed to vary in size from this fraction
        // up to 1.0 of the row's font size. The CATFORD-style layout has
        // dramatic in-row variation; bottom-aligned so smaller words sit
        // next to taller words instead of floating above them.
        let minInRowScale: CGFloat = 0.42

        // Safety cap so we don't loop forever in degenerate cases.
        let maxIterations = 400

        while y < canvas.height && iteration < maxIterations {
            iteration += 1

            // Decide the row's MAX font size (taller words define the line's
            // vertical advance; smaller words bottom-align inside it).
            let r = rng.nextDouble()
            let rowFontSize: CGFloat
            switch r {
            case 0..<0.10: rowFontSize = xlSize
            case 0.10..<0.32: rowFontSize = lgSize
            case 0.32..<0.70: rowFontSize = mdSize
            default: rowFontSize = smSize
            }

            // Fill this row. Start at a random X offset so rows don't all
            // begin on the left margin. Negative offsets mean the first
            // word is chopped on the left edge; positive offsets indent.
            var x: CGFloat = (rng.nextDouble() - 0.35) * canvas.width * 0.30
            var wordsInRow = 0

            // Allow the last word to extend slightly past the right edge
            // (clipped by the renderer) for an organic, chaotic feel.
            let rightLimit = canvas.width + rowFontSize * 0.5

            while x < rightLimit {
                // We render uppercase, so measure uppercase. Mixed-case
                // measurement was leading to a width undershoot and visible
                // overlap with the next word.
                let text = shuffled[nameCursor % totalUnique].uppercased()
                nameCursor += 1

                // Per-word size: anywhere from minInRowScale to 1.0 of the
                // row's max. Wide variance → CATFORD-style differing word
                // heights on the same line.
                let jitter = minInRowScale + rng.nextDouble() * (1.0 - minInRowScale)
                let fontSize = rowFontSize * jitter
                let width = measureWidth(text: text, fontSize: fontSize)

                // Bottom-align: shift smaller words down so their baselines
                // line up with the row's tallest words.
                let yOffset = rowFontSize - fontSize
                placed.append(
                    PlacedWord(
                        id: idCounter,
                        text: text,
                        position: CGPoint(x: x, y: y + yOffset),
                        fontSize: fontSize,
                        rotation: 0
                    ))
                idCounter += 1
                x += width + horizontalGap
                wordsInRow += 1

                if wordsInRow > 30 { break }
            }

            // Advance Y by the row's full line height so descenders/leading
            // don't overlap into the next row.
            y += rowFontSize * lineHeightFactor
        }

        return placed
    }

    static func dailySeed(for date: Date) -> UInt64 {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let y = UInt64(comps.year ?? 2026)
        let m = UInt64(comps.month ?? 1)
        let d = UInt64(comps.day ?? 1)
        return y &* 10000 &+ m &* 100 &+ d
    }

    private static func measureWidth(text: String, fontSize: CGFloat) -> CGFloat {
        let font = roundedFont(size: fontSize, weight: .bold)
        return (text as NSString).size(withAttributes: [.font: font]).width
    }

    private static func roundedFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        let base = NSFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.rounded),
            let rounded = NSFont(descriptor: descriptor, size: size)
        {
            return rounded
        }
        return base
    }
}

struct SeededRng: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0xdead_beef_0123_4567 : seed
    }

    mutating func next() -> UInt64 {
        // Linear congruential generator. Cheap and deterministic.
        state = state &* 2_862_933_555_777_941_757 &+ 3_037_000_493
        return state
    }

    mutating func nextDouble() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}
