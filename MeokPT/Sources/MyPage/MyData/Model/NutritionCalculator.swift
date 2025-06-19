import Foundation

struct NutritionValues {
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
}

struct NutrientRatios {
    let carbPercent: Double
    let proteinPercent: Double
    let fatPercent: Double
    let fiberGrams: Double
}


func calculateBMI(weightKg: Double, heightCm: Double) -> Double {
    guard heightCm > 0 else { return 0 }
    let heightM = heightCm / 100
    return weightKg / (heightM * heightM)
}

func calculateBMR(gender: Gender, weight: Double, height: Double, age: Int) -> Double {
    // Mifflin-St Jeor 공식 사용
    if gender == Gender.male {
        return 10 * weight + 6.25 * height - 5 * Double(age) + 5
    } else {
        return 10 * weight + 6.25 * height - 5 * Double(age) - 161
    }
}

func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Double {
    return bmr * activityLevel.rawValue
}

func adjustCalories(for gender: Gender, goal: Goal, tdee: Double, bmr: Double, bmi: Double) -> Double {
    switch goal {
    case .loseWeight:
        // 체중 감량: 고정된 칼로리 적자
        let deficit: Double
        if bmi < 18.5 {
            deficit = 200  // 저체중일 때는 적은 적자
        } else if bmi < 25.0 {
            deficit = 500  // 정상체중
        } else if bmi < 30.0 {
            deficit = 600  // 과체중
        } else {
            deficit = 700  // 비만
        }
        
        let proposedCalories = tdee - deficit
        
        // 최소 칼로리 제한
        let minimumCalories = gender == .female ? 1200.0 : 1500.0
        
        return max(proposedCalories, minimumCalories)
        
    case .gainMuscle:
        // 근육 증가: 200-400 칼로리 잉여
        let surplus: Double
        if bmi < 18.5 { surplus = 400 }
        else if bmi < 25.0 { surplus = 300 }
        else { surplus = 200 }
        
        return tdee + surplus
        
    case .maintainWeight:
        return tdee
    }
}

func getRatios(for gender: Gender, goal: Goal, bmi: Double) -> NutrientRatios {
    var carbP: Double
    var proteinP: Double
    var fatP: Double
    var fiberG: Double = gender == .female ? 25.0 : 30.0

    switch goal {
    case .loseWeight:
        // 체중 감량 시 단백질 비율을 높여 근육량 보존
        if bmi < 18.5 {
            carbP = 0.45; proteinP = 0.25; fatP = 0.30
        } else if bmi < 25.0 {
            carbP = 0.35; proteinP = 0.35; fatP = 0.30
        } else if bmi < 30.0 {
            carbP = 0.30; proteinP = 0.40; fatP = 0.30
            fiberG += 5.0
        } else {
            carbP = 0.25; proteinP = 0.45; fatP = 0.30
            fiberG += 8.0
        }

    case .gainMuscle:
        // 근육 증가 시 탄수화물과 단백질 충분히 공급
        if bmi < 18.5 {
            carbP = 0.50; proteinP = 0.30; fatP = 0.20
        } else if bmi < 25.0 {
            carbP = gender == .female ? 0.45 : 0.50
            proteinP = 0.30
            fatP = gender == .female ? 0.25 : 0.20
        } else {
            carbP = gender == .female ? 0.40 : 0.45
            proteinP = 0.35
            fatP = gender == .female ? 0.25 : 0.20
            fiberG += 3.0
        }
        
    case .maintainWeight:
        // 유지 시 균형잡힌 비율
        if bmi < 18.5 {
            carbP = gender == .female ? 0.50 : 0.55
            proteinP = 0.25
            fatP = gender == .female ? 0.25 : 0.20
        } else if bmi < 25.0 {
            carbP = 0.50; proteinP = 0.25; fatP = 0.25
        } else {
            carbP = gender == .female ? 0.45 : 0.50
            proteinP = 0.30
            fatP = gender == .female ? 0.25 : 0.20
            fiberG += 3.0
        }
    }
    
    // 비율 합계가 1.0이 되도록 조정
    let sumCheck = carbP + proteinP + fatP
    if abs(sumCheck - 1.0) > 0.001 {
        let adjustment = (1.0 - sumCheck) / 3.0
        carbP += adjustment
        proteinP += adjustment
        fatP += adjustment
    }

    return NutrientRatios(carbPercent: carbP, proteinPercent: proteinP, fatPercent: fatP, fiberGrams: fiberG)
}

func calculateProteinRequirement(weightKg: Double, goal: Goal, activityLevel: ActivityLevel) -> Double {
    // 체중 기반 단백질 요구량 계산 (g/kg)
    var proteinPerKg: Double
    
    switch goal {
    case .loseWeight:
        // 체중 감량 시: 1.6-2.0g/kg (근육량 보존)
        proteinPerKg = activityLevel.rawValue >= 1.55 ? 2.0 : 1.6
    case .gainMuscle:
        // 근육 증가 시: 1.8-2.2g/kg
        proteinPerKg = activityLevel.rawValue >= 1.55 ? 2.2 : 1.8
    case .maintainWeight:
        // 유지 시: 1.2-1.6g/kg
        proteinPerKg = activityLevel.rawValue >= 1.55 ? 1.6 : 1.2
    }
    
    return weightKg * proteinPerKg
}

func calculateNutrition(weight: Double, height: Double, age: Int, gender: Gender, goal: Goal, activityLevel: ActivityLevel) -> NutritionValues {
    let weightKg = weight
    let heightCm = height

    let bmr = calculateBMR(gender: gender, weight: weightKg, height: heightCm, age: age)
    let tdee = calculateTDEE(bmr: bmr, activityLevel: activityLevel)
    let bmi = calculateBMI(weightKg: weightKg, heightCm: heightCm)
    
    let adjustedCalories = adjustCalories(for: gender, goal: goal, tdee: tdee, bmr: bmr, bmi: bmi)
    let ratios = getRatios(for: gender, goal: goal, bmi: bmi)
    
    // 체중 기반 단백질 계산 우선 사용
    let proteinGrams = calculateProteinRequirement(weightKg: weightKg, goal: goal, activityLevel: activityLevel)
    
    // 단백질 칼로리를 제외한 나머지 칼로리로 탄수화물과 지방 계산
    let proteinCalories = proteinGrams * 4.0
    let remainingCalories = adjustedCalories - proteinCalories
    let fatCalorieRatio = ratios.fatPercent / (ratios.carbPercent + ratios.fatPercent)
    
    let fatGrams = (remainingCalories * fatCalorieRatio) / 9.0
    let carbsGrams = (remainingCalories * (1.0 - fatCalorieRatio)) / 4.0
    
    // 당분은 총 탄수화물의 10% 이하로 제한
    let sugarGrams = min(carbsGrams * 0.1, 50.0) // WHO 권장: 하루 50g 이하
    
    // 나트륨: 성인 권장량 2300mg, 목표 1500mg
    let sodiumMilligrams = 1500.0
    
    return NutritionValues(
        calories: adjustedCalories,
        carbs: carbsGrams,
        protein: proteinGrams,
        fat: fatGrams,
        fiber: ratios.fiberGrams,
        sugar: sugarGrams,
        sodium: sodiumMilligrams
    )
}

func calculateIdealWeight(heightCm: Double, targetBMI: Double = 22.0) -> Double {
    guard heightCm > 0 else { return 0 }
    let heightM = heightCm / 100
    return targetBMI * heightM * heightM
}

func calculateNutritionForIdealWeight(
    heightCm: Double,
    age: Int,
    gender: Gender,
    activityLevel: ActivityLevel,
    targetBMIForIdealWeight: Double = 22.0
) -> NutritionValues {
    
    let idealWeight = calculateIdealWeight(heightCm: heightCm, targetBMI: targetBMIForIdealWeight)
    
    return calculateNutrition(
        weight: idealWeight,
        height: heightCm,
        age: age,
        gender: gender,
        goal: .maintainWeight,
        activityLevel: activityLevel
    )
}


func generateNutritionItems(from nutrition: NutritionValues) -> [NutritionItem] {
    return [
        NutritionItem(type: .calorie, value: 0, max: Int(nutrition.calories.rounded())),
        NutritionItem(type: .carbohydrate, value: 0, max: Int(nutrition.carbs.rounded())),
        NutritionItem(type: .protein, value: 0, max: Int(nutrition.protein.rounded())),
        NutritionItem(type: .fat, value: 0, max: Int(nutrition.fat.rounded())),
        NutritionItem(type: .dietaryFiber, value: 0, max: Int(nutrition.fiber.rounded())),
        NutritionItem(type: .sugar, value: 0, max: Int(nutrition.sugar.rounded())),
        NutritionItem(type: .sodium, value: 0, max: Int(nutrition.sodium.rounded()))
    ]
}
