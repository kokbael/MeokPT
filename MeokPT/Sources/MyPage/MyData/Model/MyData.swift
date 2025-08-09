//
//  MyData.swift
//  MeokPT
//
//  Created by 김동영 on 8/9/25.
//

import Foundation
import SwiftData

@Model
final class MyData {
    @Attribute(.unique) var id: UUID
    var myHeight: String
    var myAge: String
    var myWeight: String
    var selectedGenderFilter: GenderFilter
    var selectedTargetFilter: TargetFilter
    var activityLevel: ActivityLevel

    init(id: UUID, myHeight: String, myAge: String, myWeight: String, selectedGenderFilter: GenderFilter, selectedTargetFilter: TargetFilter, activityLevel: ActivityLevel) {
        self.id = id
        self.myHeight = myHeight
        self.myAge = myAge
        self.myWeight = myWeight
        self.selectedGenderFilter = selectedGenderFilter
        self.selectedTargetFilter = selectedTargetFilter
        self.activityLevel = activityLevel
    }
}
