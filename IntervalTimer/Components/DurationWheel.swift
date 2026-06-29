import SwiftUI

/// Three side-by-side rotary wheels: hr / min / sec, bound to a total seconds Int.
struct DurationWheel: View {
    @Binding var seconds: Int

    private var h: Int { seconds / 3600 }
    private var m: Int { (seconds % 3600) / 60 }
    private var s: Int { seconds % 60 }

    var body: some View {
        HStack(spacing: 0) {
            wheel(value: hBinding, range: 0..<24, suffix: "hr")
            wheel(value: mBinding, range: 0..<60, suffix: "min")
            wheel(value: sBinding, range: 0..<60, suffix: "sec")
        }
        .frame(height: 180)
    }

    private func wheel(value: Binding<Int>, range: Range<Int>, suffix: String) -> some View {
        Picker("", selection: value) {
            ForEach(range, id: \.self) { v in
                Text("\(v) \(suffix)").tag(v)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var hBinding: Binding<Int> {
        Binding(get: { h }, set: { seconds = $0 * 3600 + m * 60 + s })
    }
    private var mBinding: Binding<Int> {
        Binding(get: { m }, set: { seconds = h * 3600 + $0 * 60 + s })
    }
    private var sBinding: Binding<Int> {
        Binding(get: { s }, set: { seconds = h * 3600 + m * 60 + $0 })
    }
}
