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
              let activityLevel = state.activityLevel else {
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
        
        state.myKcal = targetKcal
        
        // 4. 탄단지 비율 설정
        let carbRatio, proteinRatio, fatRatio: Double
        switch state.selectedTargetFilter {
        case .weightLoss:
            (carbRatio, proteinRatio, fatRatio) = (0.4, 0.4, 0.2)
        case .weightGain:
            (carbRatio, proteinRatio, fatRatio) = (0.5, 0.3, 0.2)
        case .healthy:
            (carbRatio, proteinRatio, fatRatio) = (0.5, 0.2, 0.3)
        case .vegan:
            (carbRatio, proteinRatio, fatRatio) = (0.6, 0.2, 0.2)
        }
        
        state.myCarbohydrate = (targetKcal * carbRatio) / 4
        state.myProtein = (targetKcal * proteinRatio) / 4
        state.myFat = (targetKcal * fatRatio) / 9
        
        // 5. 기타 영양소 (일반 권장량)
        state.myDietaryFiber = 25
        state.mySodium = 2000
        state.mySugar = 50
    }
}
