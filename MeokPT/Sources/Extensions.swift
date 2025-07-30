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
    
    // Double 값을 상황에 맞게 포맷팅하는 계산 프로퍼티
    var formattedString: String {
        // 값이 정수이면 ".0" 없이, 소수이면 소수점 첫째 자리까지 표시
        return self.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%.1f", self)
    }
}

extension String {
    // 숫자와 첫 번째 소수점 외의 모든 문자를 제거합니다.
    func sanitizedForDouble() -> String {
        let filtered = self.filter { "0123456789.".contains($0) }
        var components = filtered.components(separatedBy: ".")
        if components.count > 1 {
            let integerPart = components.removeFirst()
            return "\(integerPart).\(components.joined())"
        }
        return filtered
    }
    
    // 문자열을 반올림하여 소수점 첫째 자리까지 표현하는 Double로 변환합니다.
    func toDoubleAndRound() -> Double? {
        guard let value = Double(self) else { return nil }
        return (value * 10).rounded() / 10
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
