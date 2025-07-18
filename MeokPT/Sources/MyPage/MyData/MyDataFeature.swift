//
//  MyDataFeature.swift
//  MeokPT
//
//  Created by 김동영 on 7/18/25.
//

import ComposableArchitecture
import Foundation
import SwiftData

enum ViewFilter: String, CaseIterable, Identifiable {
    case myData = "내 정보"
    case targetNutrient = "목표 섭취량"
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
        var selectedViewFilter: ViewFilter = .myData
        var myHeight: String = ""
        var myAge: String = ""
        var myWeight: String = ""
        var selectedGenderFilter: GenderFilter = .male
        var selectedTargetFilter: TargetFilter = .weightLoss
        @Presents var activityLevelSheet: ActivityLevelFeature.State?

    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case presentActivityLevelSheet
        case activityLevelSheetAction(PresentationAction<ActivityLevelFeature.Action>)
        case dismissSheet

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
                
            case .activityLevelSheetAction(.presented(.delegate(.dismissSheet))):
                return .send(.dismissSheet)
                
            case .dismissSheet:
                state.activityLevelSheet = nil
                return .none

            case .activityLevelSheetAction(_):
                return .none
                
            case .binding(_):
                return .none
            }
        }
        .ifLet(\.$activityLevelSheet, action: \.activityLevelSheetAction) {
            ActivityLevelFeature()
        }
    }
}
