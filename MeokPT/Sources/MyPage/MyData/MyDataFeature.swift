//
//  MyDataFeature.swift
//  MeokPT
//
//  Created by 김동영 on 7/18/25.
//

import ComposableArchitecture
import Foundation
import SwiftData

enum NutrientField: Hashable {
    case kcal, carbohydrate, protein, fat, dietaryFiber, sodium, sugar
}

enum BodyField: Hashable {
    case heightField, ageField, weightField
}

enum AutoOrCustomFilter: String, CaseIterable, Identifiable {
    case custom = " 직접 입력 "
    case auto = " 자동 계산 "
    var id: String { self.rawValue }
}

enum GenderFilter: String, CaseIterable, Identifiable, Codable {
    case male = "남성"
    case female = "여성"
    var id: String { self.rawValue }
}

enum TargetFilter: String, CaseIterable, Identifiable, Codable {
    case weightLoss = "체중 감량"
    case weightGain = "체중 증량"
    case healthy = "건강 유지"
    case vegan = "채식 위주"
    var id: String { self.rawValue }
}

@Reducer
struct MyDataFeature {
    @ObservableState
    struct State: Equatable {
        var selectedAutoOrCustomFilter: AutoOrCustomFilter = .custom
        var focusedNutrientField: NutrientField?
        
        // SwiftData 모델
        var myData: MyData?
        var targetNutrient: TargetNutrient?
        
        // 직접 입력을 위한 임시 상태
        var customKcal: String = ""
        var customCarbohydrate: String = ""
        var customProtein: String = ""
        var customFat: String = ""
        var customDietaryFiber: String = ""
        var customSodium: String = ""
        var customSugar: String = ""
        
        var isCustomSaveButtonDisabled: Bool {
            customKcal.isEmpty || customCarbohydrate.isEmpty || customProtein.isEmpty ||
            customFat.isEmpty || customDietaryFiber.isEmpty || customSodium.isEmpty ||
            customSugar.isEmpty
        }
        
        // 자동 계산을 위한 신체 정보
        var myHeight: String = ""
        var myAge: String = ""
        var myWeight: String = ""
        var isUpdateNutrientDisabled: Bool {
            myHeight.isEmpty || myAge.isEmpty || myWeight.isEmpty || activityLevel == nil
        }
        var selectedGenderFilter: GenderFilter = .male
        var selectedTargetFilter: TargetFilter = .weightLoss
        var activityLevel: ActivityLevel?
        var activityLevelTitle: String = "활동량 선택하기"
        var scrollToTopID: UUID = UUID()
        var scrollToBottomID: UUID = UUID()
        @Presents var activityLevelSheet: ActivityLevelFeature.State?
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case presentActivityLevelSheet
        case activityLevelSheetAction(PresentationAction<ActivityLevelFeature.Action>)
        case dismissSheet
        case calculateNutrients
        case updateNutrientsTapped
        case saveCustomNutrientsTapped
        case formatCustomNutrientField(NutrientField?)
        case myDataLoaded(MyData?)
        case targetNutrientLoaded(TargetNutrient?)
    }
    
    @Dependency(\.modelContainer) var modelContainer
    
    var body: some ReducerOf<Self> {
        BindingReducer()
            .onChange(of: \.focusedNutrientField) { oldValue, _ in
                Reduce { _, _ in
                    // 포커스가 있던 필드에서 다른 곳으로 이동하면 (nil이 되거나 다른 필드로)
                    // 이전 필드를 포맷팅하는 액션을 보냅니다.
                    if let field = oldValue {
                        return .send(.formatCustomNutrientField(field))
                    }
                    return .none
                }
            }
            .onChange(of: \.selectedAutoOrCustomFilter) { _, newValue in
                Reduce { state, _ in
                    if newValue == .auto {
                        state.scrollToBottomID = UUID()
                    }
                    return .none
                }
            }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await MainActor.run {
                        let context = modelContainer.mainContext
                        
                        let myDataDescriptor = FetchDescriptor<MyData>()
                        let myData = try? context.fetch(myDataDescriptor).first
                        send(.myDataLoaded(myData))
                        
                        let targetNutrientDescriptor = FetchDescriptor<TargetNutrient>()
                        let targetNutrient = try? context.fetch(targetNutrientDescriptor).first
                        send(.targetNutrientLoaded(targetNutrient))
                    }
                }
                
            case .myDataLoaded(let myData):
                if let myData {
                    state.myData = myData
                    state.myHeight = myData.myHeight
                    state.myAge = myData.myAge
                    state.myWeight = myData.myWeight
                    state.selectedGenderFilter = myData.selectedGenderFilter
                    state.selectedTargetFilter = myData.selectedTargetFilter
                    state.activityLevel = myData.activityLevel
                    state.activityLevelTitle = myData.activityLevel.title
                }
                return .none
                
            case .targetNutrientLoaded(let targetNutrient):
                if let targetNutrient {
                    state.targetNutrient = targetNutrient
                    // 자동계산이 아닌 직접입력 값을 보여주기 위함
                    state.customKcal = targetNutrient.myKcal.formattedString
                    state.customCarbohydrate = targetNutrient.myCarbohydrate.formattedString
                    state.customProtein = targetNutrient.myProtein.formattedString
                    state.customFat = targetNutrient.myFat.formattedString
                    state.customDietaryFiber = targetNutrient.myDietaryFiber.formattedString
                    state.customSodium = targetNutrient.mySodium.formattedString
                    state.customSugar = targetNutrient.mySugar.formattedString
                }
                return .none
                
            case .presentActivityLevelSheet:
                state.activityLevelSheet = ActivityLevelFeature.State()
                return .none
                
            case .activityLevelSheetAction(.presented(.delegate(.selectedLevel(let level)))):
                state.activityLevel = level
                state.activityLevelTitle = level.title
                return .send(.dismissSheet)
                
            case .activityLevelSheetAction(.presented(.delegate(.dismissSheet))):
                return .send(.dismissSheet)
                
            case .dismissSheet:
                state.activityLevelSheet = nil
                return .none

            case .activityLevelSheetAction(_):
                return .none
                
            case .formatCustomNutrientField(let field):
                guard let field = field else { return .none }
                switch field {
                case .kcal:
                    if let roundedValue = state.customKcal.toDoubleAndRound() {
                        state.customKcal = roundedValue.formattedString
                    }
                case .carbohydrate:
                    if let roundedValue = state.customCarbohydrate.toDoubleAndRound() {
                        state.customCarbohydrate = roundedValue.formattedString
                    }
                case .protein:
                    if let roundedValue = state.customProtein.toDoubleAndRound() {
                        state.customProtein = roundedValue.formattedString
                    }
                case .fat:
                    if let roundedValue = state.customFat.toDoubleAndRound() {
                        state.customFat = roundedValue.formattedString
                    }
                case .dietaryFiber:
                    if let roundedValue = state.customDietaryFiber.toDoubleAndRound() {
                        state.customDietaryFiber = roundedValue.formattedString
                    }
                case .sodium:
                    if let roundedValue = state.customSodium.toDoubleAndRound() {
                        state.customSodium = roundedValue.formattedString
                    }
                case .sugar:
                    if let roundedValue = state.customSugar.toDoubleAndRound() {
                        state.customSugar = roundedValue.formattedString
                    }
                }
                return .none
                
            case .updateNutrientsTapped:
                state.scrollToTopID = UUID()
                return .send(.calculateNutrients)
                
            case .calculateNutrients:
                let myData: MyData
                let isNewMyData: Bool
                if let existingMyData = state.myData {
                    myData = existingMyData
                    isNewMyData = false
                } else {
                    guard let activityLevel = state.activityLevel else { return .none }
                    let newMyData = MyData(id: UUID(), myHeight: state.myHeight, myAge: state.myAge, myWeight: state.myWeight, selectedGenderFilter: state.selectedGenderFilter, selectedTargetFilter: state.selectedTargetFilter, activityLevel: activityLevel)
                    state.myData = newMyData
                    myData = newMyData
                    isNewMyData = true
                }
                
                // 비동기 작업을 위해 필요한 데이터 저장
                let myDataId = myData.id
                let height = state.myHeight
                let age = state.myAge
                let weight = state.myWeight
                let genderFilter = state.selectedGenderFilter
                let targetFilter = state.selectedTargetFilter
                let activityLevel = state.activityLevel
                
                // 로컬 객체 업데이트
                myData.myHeight = height
                myData.myAge = age
                myData.myWeight = weight
                myData.selectedGenderFilter = genderFilter
                myData.selectedTargetFilter = targetFilter
                if let activityLevel = activityLevel {
                    myData.activityLevel = activityLevel
                }

                let targetNutrient: TargetNutrient
                let isNewTargetNutrient: Bool
                if let existingTargetNutrient = state.targetNutrient {
                    targetNutrient = existingTargetNutrient
                    isNewTargetNutrient = false
                } else {
                    let newTargetNutrient = TargetNutrient(id: UUID(), myKcal: 0, myCarbohydrate: 0, myProtein: 0, myFat: 0, myDietaryFiber: 0, mySodium: 0, mySugar: 0)
                    state.targetNutrient = newTargetNutrient
                    targetNutrient = newTargetNutrient
                    isNewTargetNutrient = true
                }
                
                calculateNutrients(state: &state, targetNutrient: targetNutrient)
                
                // 비동기 작업을 위해 계산된 값 저장
                let targetNutrientId = targetNutrient.id
                let kcal = targetNutrient.myKcal
                let carbohydrate = targetNutrient.myCarbohydrate
                let protein = targetNutrient.myProtein
                let fat = targetNutrient.myFat
                let dietaryFiber = targetNutrient.myDietaryFiber
                let sodium = targetNutrient.mySodium
                let sugar = targetNutrient.mySugar
                
                return .run { _ in
                    await MainActor.run {
                        let context = modelContainer.mainContext
                        
                        // MyData 처리
                        if isNewMyData {
                            let newMyData = MyData(id: myDataId, myHeight: height, myAge: age, myWeight: weight, selectedGenderFilter: genderFilter, selectedTargetFilter: targetFilter, activityLevel: activityLevel!)
                            context.insert(newMyData)
                        } else {
                            // 기존 MyData 찾아 업데이트
                            let descriptor = FetchDescriptor<MyData>(predicate: #Predicate { $0.id == myDataId })
                            if let existingMyData = try? context.fetch(descriptor).first {
                                existingMyData.myHeight = height
                                existingMyData.myAge = age
                                existingMyData.myWeight = weight
                                existingMyData.selectedGenderFilter = genderFilter
                                existingMyData.selectedTargetFilter = targetFilter
                                if let activityLevel = activityLevel {
                                    existingMyData.activityLevel = activityLevel
                                }
                            }
                        }
                        
                        // TargetNutrient 처리
                        if isNewTargetNutrient {
                            let newTargetNutrient = TargetNutrient(id: targetNutrientId, myKcal: kcal, myCarbohydrate: carbohydrate, myProtein: protein, myFat: fat, myDietaryFiber: dietaryFiber, mySodium: sodium, mySugar: sugar)
                            context.insert(newTargetNutrient)
                        } else {
                            // 기존 TargetNutrient 찾아 업데이트
                            let descriptor = FetchDescriptor<TargetNutrient>(predicate: #Predicate { $0.id == targetNutrientId })
                            if let existingTargetNutrient = try? context.fetch(descriptor).first {
                                existingTargetNutrient.myKcal = kcal
                                existingTargetNutrient.myCarbohydrate = carbohydrate
                                existingTargetNutrient.myProtein = protein
                                existingTargetNutrient.myFat = fat
                                existingTargetNutrient.myDietaryFiber = dietaryFiber
                                existingTargetNutrient.mySodium = sodium
                                existingTargetNutrient.mySugar = sugar
                            }
                        }
                        
                        try? context.save()
                    }
                }

            case .saveCustomNutrientsTapped:
                let targetNutrient: TargetNutrient
                let isNewTargetNutrient: Bool
                if let existingTargetNutrient = state.targetNutrient {
                    targetNutrient = existingTargetNutrient
                    isNewTargetNutrient = false
                } else {
                    let newTargetNutrient = TargetNutrient(id: UUID(), myKcal: 0, myCarbohydrate: 0, myProtein: 0, myFat: 0, myDietaryFiber: 0, mySodium: 0, mySugar: 0)
                    state.targetNutrient = newTargetNutrient
                    targetNutrient = newTargetNutrient
                    isNewTargetNutrient = true
                }
                
                // 비동기 작업을 위한 값 추출
                let targetNutrientId = targetNutrient.id
                let kcal = Double(state.customKcal) ?? 0
                let carbohydrate = Double(state.customCarbohydrate) ?? 0
                let protein = Double(state.customProtein) ?? 0
                let fat = Double(state.customFat) ?? 0
                let dietaryFiber = Double(state.customDietaryFiber) ?? 0
                let sodium = Double(state.customSodium) ?? 0
                let sugar = Double(state.customSugar) ?? 0
                
                // 로컬 객체 업데이트
                targetNutrient.myKcal = kcal
                targetNutrient.myCarbohydrate = carbohydrate
                targetNutrient.myProtein = protein
                targetNutrient.myFat = fat
                targetNutrient.myDietaryFiber = dietaryFiber
                targetNutrient.mySodium = sodium
                targetNutrient.mySugar = sugar
                
                return .run { _ in
                    await MainActor.run {
                        let context = modelContainer.mainContext
                        
                        if isNewTargetNutrient {
                            let newTargetNutrient = TargetNutrient(id: targetNutrientId, myKcal: kcal, myCarbohydrate: carbohydrate, myProtein: protein, myFat: fat, myDietaryFiber: dietaryFiber, mySodium: sodium, mySugar: sugar)
                            context.insert(newTargetNutrient)
                        } else {
                            // 기존 TargetNutrient 찾아 업데이트
                            let descriptor = FetchDescriptor<TargetNutrient>(predicate: #Predicate { $0.id == targetNutrientId })
                            if let existingTargetNutrient = try? context.fetch(descriptor).first {
                                existingTargetNutrient.myKcal = kcal
                                existingTargetNutrient.myCarbohydrate = carbohydrate
                                existingTargetNutrient.myProtein = protein
                                existingTargetNutrient.myFat = fat
                                existingTargetNutrient.myDietaryFiber = dietaryFiber
                                existingTargetNutrient.mySodium = sodium
                                existingTargetNutrient.mySugar = sugar
                            }
                        }
                        
                        try? context.save()
                    }
                }
                
            case .binding(_):
                return .none
            }
        }
        .ifLet(\.$activityLevelSheet, action: \.activityLevelSheetAction) {
            ActivityLevelFeature()
        }
    }
    
    private func calculateNutrients(state: inout State, targetNutrient: TargetNutrient) {
        guard state.selectedAutoOrCustomFilter == .auto,
              let height = Double(state.myHeight),
              let weight = Double(state.myWeight),
              let age = Double(state.myAge),
              let activityLevel = state.activityLevel,
              weight > 0 else {
            return
        }
        
        // 1. BMR 계산 (Mifflin-St Jeor)
        let bmr: Double
        switch state.selectedGenderFilter {
        case .male:
            bmr = 10 * weight + 6.25 * height - 5 * age + 5
        case .female:
            bmr = 10 * weight + 6.25 * height - 5 * age - 161
        }
        
        // 2. TDEE (총 소모 칼로리) 계산
        let tdee = bmr * activityLevel.rawValue
        
        // 3. 목표에 따른 칼로리 조정
        var calculatedKcal = tdee
        switch state.selectedTargetFilter {
        case .weightLoss:
            calculatedKcal -= 500
        case .weightGain:
            calculatedKcal += 500
        case .healthy, .vegan:
            break
        }
        
        targetNutrient.myKcal = max(0, calculatedKcal)
        
        // 4. 목표별 단백질 섭취량 계산 (체중 기반)
        let proteinPerKg: Double
        switch state.selectedTargetFilter {
        case .weightLoss, .weightGain:
            proteinPerKg = 1.7
        case .healthy, .vegan:
            proteinPerKg = 1.2
        }
        let proteinInGrams = weight * proteinPerKg
        targetNutrient.myProtein = proteinInGrams
        
        let proteinInCalories = proteinInGrams * 4
        
        // 5. 지방 섭취량 계산 (총 칼로리의 25%)
        let fatInCalories = calculatedKcal * 0.25
        let fatInGrams = fatInCalories / 9
        targetNutrient.myFat = fatInGrams
        
        // 6. 탄수화물 섭취량 계산 (나머지 칼로리)
        let carbInCalories = calculatedKcal - proteinInCalories - fatInCalories
        let carbInGrams = carbInCalories / 4
        targetNutrient.myCarbohydrate = max(0, carbInGrams) // 탄수화물이 음수가 되지 않도록 보장
        
        // 7. 기타 영양소 계산
        // 식이섬유: 1,000 kcal 당 14g
        targetNutrient.myDietaryFiber = (calculatedKcal / 1000) * 14
        // 나트륨: WHO 권장 상한선
        targetNutrient.mySodium = 2300
        // 당류: AHA 권장량 (성별 기반)
        switch state.selectedGenderFilter {
        case .male:
            targetNutrient.mySugar = 36
        case .female:
            targetNutrient.mySugar = 25
        }
    }
}
