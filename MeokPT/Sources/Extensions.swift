//
//  Extensions.swift
//  MeokPT
//
//  Created by 김동영 on 7/16/25.
//
import Foundation

extension Double {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
