import SwiftUI
import ComposableArchitecture

// 영양성분 데이터 모델
struct Nutrient: Identifiable, Equatable {
    let label: String
    let value: Double
    let unit: String
    var id: String { label }
}

// 분석용 데이터 모델
struct AnalyzeData: Identifiable, Equatable {
    let nutrient: Nutrient
    let maxValue: Double
    let barColor: Color
    var id: String { nutrient.id }
}

@Reducer
struct AnalyzeFeature {
    @ObservableState
    struct State: Equatable {
        var currentNutrients: [Nutrient] = [
            .init(label: "열량", value: 2100, unit: "kcal"),
            .init(label: "탄수화물", value: 250, unit: "g"),
            .init(label: "단백질", value: 150, unit: "g"),
            .init(label: "지방", value: 80, unit: "g"),
            .init(label: "식이섬유", value: 25, unit: "g"),
            .init(label: "당류", value: 60, unit: "g"),
            .init(label: "나트륨", value: 1800, unit: "mg")
        ]
        
        var maxValues: [String: Double] = [
            "열량": 2400,
            "탄수화물": 324,
            "단백질": 60,
            "지방": 51,
            "식이섬유": 25,
            "당류": 50,
            "나트륨": 2000
        ]
        
        var analyzeItems: [AnalyzeData] {
            currentNutrients.map { nutrient in
                // 1. maxValue 계산
                let maxValue = maxValues[nutrient.label] ?? nutrient.value * 1.5
                
                // 2. barColor 계산
                let percentage = nutrient.value / maxValue
                let barColor: Color
                if percentage < 0.8 {
                    barColor = .blue
                } else if percentage <= 1.0 {
                    barColor = .green
                } else if percentage <= 1.2 {
                    barColor = .orange
                } else {
                    barColor = .red
                }
                
                // 3. 분석된 데이터 반환
                return AnalyzeData(nutrient: nutrient, maxValue: maxValue, barColor: barColor)
            }
        }
        
        @Presents var analyzeAddDietSheet: AnalyzeAddDietFeature.State?
    }
    
    enum Action: BindableAction {
        case presentAnalyzeAddDietSheet
        case binding(BindingAction<State>)
        case delegate(DelegateAction)
        case analyzeAddDietAction(PresentationAction<AnalyzeAddDietFeature.Action>)
    }
    
    enum DelegateAction {
        case navigateToMyPage
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .presentAnalyzeAddDietSheet:
                state.analyzeAddDietSheet = AnalyzeAddDietFeature.State()
                return .none
                
            case .analyzeAddDietAction(_):
                return .none
                
            case .delegate(_):
                return .none
            case .binding(_):
                return .none
            }
        }
        .ifLet(\.$analyzeAddDietSheet, action: \.analyzeAddDietAction) {
            AnalyzeAddDietFeature()
        }
    }
}
