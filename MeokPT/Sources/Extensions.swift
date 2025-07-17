//
//  Extensions.swift
//  MeokPT
//
//  Created by 김동영 on 7/16/25.
//
import Foundation
import SwiftUI

extension Double {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}

// MARK: - Wiggle Animation Effect
struct WiggleModifier: ViewModifier {
    let isWiggling: Bool

    func body(content: Content) -> some View {
        if isWiggling {
            TimelineView(.periodic(from: .now, by: 0.6)) { _ in
                content
                    .keyframeAnimator(initialValue: Angle.zero) { view, angle in
                        view.rotationEffect(angle, anchor: .center)
                    } keyframes: { _ in
                        KeyframeTrack(\.self) {
                            LinearKeyframe(.degrees(1.5), duration: 0.1)
                            LinearKeyframe(.degrees(-1.5), duration: 0.2)
                            LinearKeyframe(.degrees(1.5), duration: 0.2)
                            LinearKeyframe(.degrees(0), duration: 0.1)
                        }
                    }
            }
        } else {
            content
                .rotationEffect(.zero)
                .animation(.spring(duration: 0.3), value: isWiggling)
        }
    }
}

extension View {
    func wiggle(isWiggling: Bool) -> some View {
        self.modifier(WiggleModifier(isWiggling: isWiggling))
    }
}
