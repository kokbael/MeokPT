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
    case auto = " 자동 계산 "
    case custom = " 직접 입력 "
    var id: String { self.rawValue }
}

enum GenderFilter: String, CaseIterable, Identifiable {
    case male = "남성"
    case female = "여성"
    var id: String { self.rawValue }
}

enum TargetFilter: String, CaseIterable, Identifiable {
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
        var selectedAutoOrCustomFilter: AutoOrCustomFilter = .auto
        // 자동 계산 or 직접 입력한 영양성분
        var myKcal: Double?
        var myCarbohydrate: Double?
        var myProtein: Double?
        var myFat: Double?
        var myDietaryFiber: Double?
        var mySodium: Double?
        var mySugar: Double?
        // 신체 정보
        var myHeight: String = ""
        var myAge: String = ""
        var myWeight: String = ""
        var selectedGenderFilter: GenderFilter = .male
        var selectedTargetFilter: TargetFilter = .weightLoss
        var activityLevel: ActivityLevel?
        var activityLevelTitle: String = "활동량 선택하기"
        @Presents var activityLevelSheet: ActivityLevelFeature.State?
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case presentActivityLevelSheet
        case activityLevelSheetAction(PresentationAction<ActivityLevelFeature.Action>)
        case dismissSheet
        case calculateNutrients
    }
    
    enum DelegateAction: Equatable {
        
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .presentActivityLevelSheet:
                state.activityLevelSheet = ActivityLevelFeature.State()
                return .none
                
            case .activityLevelSheetAction(.presented(.delegate(.selectedLevel(let level)))):
                state.activityLevel = level
                state.activityLevelTitle = level.title
                return .run { send in
                    await send(.calculateNutrients)
                    await send(.dismissSheet)
                }
                
            case .activityLevelSheetAction(.presented(.delegate(.dismissSheet))):
                return .send(.dismissSheet)
                
            case .dismissSheet:
                state.activityLevelSheet = nil
                return .none

            case .activityLevelSheetAction(_):
                return .none
                
            case .binding(\.selectedAutoOrCustomFilter):
                if state.selectedAutoOrCustomFilter == .auto {
                    return .send(.calculateNutrients)
                }
                return .none
                
            case .binding(\.selectedGenderFilter),
                 .binding(\.selectedTargetFilter),
                 .binding(\.myHeight),
                 .binding(\.myAge),
                 .binding(\.myWeight):
                return .send(.calculateNutrients)
                
            case .calculateNutrients:
                calculateNutrients(state: &state)
                return .none
                
            case .binding(_):
                return .none
            }
        }
        .ifLet(\.$activityLevelSheet, action: \.activityLevelSheetAction) {
            ActivityLevelFeature()
        }
    }
    
    private func calculateNutrients(state: inout State) {
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
        var targetKcal = tdee
        switch state.selectedTargetFilter {
        case .weightLoss:
            targetKcal -= 500
        case .weightGain:
            targetKcal += 500
        case .healthy, .vegan:
            break
        }
        
        state.myKcal = max(0, targetKcal)
        
        // 4. 목표별 단백질 섭취량 계산 (체중 기반)
        let proteinPerKg: Double
        switch state.selectedTargetFilter {
        case .weightLoss, .weightGain:
            proteinPerKg = 1.7
        case .healthy, .vegan:
            proteinPerKg = 1.2
        }
        let proteinInGrams = weight * proteinPerKg
        state.myProtein = proteinInGrams
        
        let proteinInCalories = proteinInGrams * 4
        
        // 5. 지방 섭취량 계산 (총 칼로리의 25%)
        let fatInCalories = targetKcal * 0.25
        let fatInGrams = fatInCalories / 9
        state.myFat = fatInGrams
        
        // 6. 탄수화물 섭취량 계산 (나머지 칼로리)
        let carbInCalories = targetKcal - proteinInCalories - fatInCalories
        let carbInGrams = carbInCalories / 4
        state.myCarbohydrate = max(0, carbInGrams) // 탄수화물이 음수가 되지 않도록 보장
        
        // 7. 기타 영양소 계산
        // 식이섬유: 1,000 kcal 당 14g
        state.myDietaryFiber = (targetKcal / 1000) * 14
        // 나트륨: WHO 권장 상한선
        state.mySodium = 2300
        // 당류: AHA 권장량 (성별 기반)
        switch state.selectedGenderFilter {
        case .male:
            state.mySugar = 36
        case .female:
            state.mySugar = 25
        }
    }
}
