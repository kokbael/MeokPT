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
    @State private var wigglingState = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(wigglingState ? 1.0 : 0), anchor: .center)
            .animation(wigglingState ? .easeInOut(duration: 0.15).repeatForever(autoreverses: true) : .spring(duration: 0.3), value: wigglingState)
            .onAppear {
                // onAppear is needed to start the animation when the view first appears in an already-editing state
                wigglingState = isWiggling
            }
            .onChange(of: isWiggling) {
                wigglingState = isWiggling
            }
    }
}

extension View {
    func wiggle(isWiggling: Bool) -> some View {
        self.modifier(WiggleModifier(isWiggling: isWiggling))
    }
}
