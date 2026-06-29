import SwiftUI

/// Fireworks-style one-shot burst: small sparks in the interval palette, in
/// staggered waves, ease-out radial explosion + gravity drift + late fade.
/// Fills its parent and bursts from the parent's center.
struct Confetti: View {
    private struct Spark {
        let angle: Double
        let speed: Double
        let wave: Double      // start delay
        let size: Double
        let color: Color
    }

    private let sparks: [Spark]
    private let start = Date()
    private let duration = 1.8

    init(count: Int = 90) {
        let colors = Palette.intervalColors.map { Color(hex: $0) }
        sparks = (0..<count).map { i in
            Spark(
                angle: Double.random(in: 0..<(2 * .pi)),
                speed: Double.random(in: 120...260),
                wave: Double(i % 3) * 0.12,
                size: Double.random(in: 4...9),
                color: colors[i % colors.count]
            )
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            Canvas { ctx, size in
                let cx = size.width / 2
                let cy = size.height / 2
                for spark in sparks {
                    let local = elapsed - spark.wave
                    guard local >= 0, local <= duration else { continue }
                    let p = local / duration
                    let ease = 1 - pow(1 - p, 3)               // ease-out expansion
                    let dist = spark.speed * ease
                    let gravity = 220 * p * p                  // quadratic downward drift
                    let x = cx + cos(spark.angle) * dist
                    let y = cy + sin(spark.angle) * dist + gravity
                    let opacity = p < 0.7 ? 1 : max(0, 1 - (p - 0.7) / 0.3)
                    let rect = CGRect(x: x - spark.size / 2, y: y - spark.size / 2,
                                      width: spark.size, height: spark.size)
                    ctx.opacity = opacity
                    ctx.fill(Path(ellipseIn: rect), with: .color(spark.color))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
