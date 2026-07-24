import SwiftUI

/// Horizontal replacement for the phone's circular ProgressRing, used only on the
/// watch to save vertical space. `progress` fills left-to-right as it grows toward 1.
/// No implicit animation: the caller feeds exact per-frame values via TimelineView.
struct LinearProgressBar: View {
    var progress: Double
    var color: Color
    /// nil = the themed ring track; the flood run passes white@30.
    var track: Color?

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let theme = ThemeColors.for(scheme)
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track ?? theme.ringTrack)
                Capsule().fill(color)
                    .frame(width: geo.size.width * max(0, min(1, progress)))
            }
        }
    }
}
