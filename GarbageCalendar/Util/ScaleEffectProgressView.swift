import SwiftUI

struct ScaleEffectProgressView: View {
    private let scaleEffect: CGFloat

    init(_ scaleEffect: CGFloat) {
        self.scaleEffect = scaleEffect
    }

    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .scaleEffect(scaleEffect)
            .frame(width: scaleEffect * 20, height: scaleEffect * 20)
    }
}
