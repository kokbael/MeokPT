//
//  TargetNutrient.swift
//  MeokPT
//
//  Created by 김동영 on 8/9/25.
//

import Foundation
import SwiftData

@Model
final class TargetNutrient {
    @Attribute(.unique) var id: UUID
    var myKcal: Double
    var myCarbohydrate: Double
    var myProtein: Double
    var myFat: Double
    var myDietaryFiber: Double
    var mySodium: Double
    var mySugar: Double

    init(id: UUID, myKcal: Double, myCarbohydrate: Double, myProtein: Double, myFat: Double, myDietaryFiber: Double, mySodium: Double, mySugar: Double) {
        self.id = id
        self.myKcal = myKcal
        self.myCarbohydrate = myCarbohydrate
        self.myProtein = myProtein
        self.myFat = myFat
        self.myDietaryFiber = myDietaryFiber
        self.mySodium = mySodium
        self.mySugar = mySugar
    }
}
