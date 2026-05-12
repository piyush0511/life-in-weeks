import LifeInWeeksCore
import SwiftUI

struct CountryBackdrop: View {
    let canvas: CGSize
    let countries: [String]
    let color: Color
    let opacity: Double
    let date: Date

    var body: some View {
        let placements = BackdropLayout.compute(
            countries: countries,
            canvas: canvas,
            seed: BackdropLayout.dailySeed(for: date)
        )

        Canvas { ctx, _ in
            for word in placements {
                let text =
                    Text(word.text)
                    .font(
                        .system(
                            size: word.fontSize,
                            weight: .bold,
                            design: .rounded)
                    )
                    .foregroundColor(color)

                let resolved = ctx.resolve(text)

                if word.rotation == 0 {
                    ctx.draw(
                        resolved,
                        at: word.position,
                        anchor: .topLeading
                    )
                } else {
                    ctx.drawLayer { inner in
                        inner.translateBy(
                            x: word.position.x, y: word.position.y)
                        inner.rotate(by: .degrees(word.rotation))
                        inner.draw(
                            resolved,
                            at: .zero,
                            anchor: .topLeading
                        )
                    }
                }
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .clipped()
    }
}
