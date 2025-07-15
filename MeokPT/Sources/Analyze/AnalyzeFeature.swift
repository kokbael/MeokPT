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

struct SelectedDiet: Identifiable, Equatable {
    let id: UUID
    let diet: Diet
    let foods: [Food]
    
    init(id: UUID = UUID(), diet: Diet) {
        self.id = id
        self.diet = diet
        self.foods = diet.foods
    }
}

@Reducer
struct AnalyzeFeature {
    @ObservableState
    struct State: Equatable {
        var isExpanded: Bool = false
        var selectedDiets: [SelectedDiet] = []
        var currentNutrients: [Nutrient] {
            var totalKcal: Double = 0
            var totalCarbohydrate: Double = 0
            var totalProtein: Double = 0
            var totalFat: Double = 0
            var totalDietaryFiber: Double = 0
            var totalSugar: Double = 0
            var totalSodium: Double = 0
            
            for diet in selectedDiets {
                for food in diet.foods {
                    totalKcal += food.kcal
                    totalCarbohydrate += food.carbohydrate ?? 0
                    totalProtein += food.protein ?? 0
                    totalFat += food.fat ?? 0
                    totalDietaryFiber += food.dietaryFiber ?? 0
                    totalSugar += food.sugar ?? 0
                    totalSodium += food.sodium ?? 0
                }
            }
            
            return [
                .init(label: "열량", value: totalKcal, unit: "kcal"),
                .init(label: "탄수화물", value: totalCarbohydrate, unit: "g"),
                .init(label: "단백질", value: totalProtein, unit: "g"),
                .init(label: "지방", value: totalFat, unit: "g"),
                .init(label: "식이섬유", value: totalDietaryFiber, unit: "g"),
                .init(label: "당류", value: totalSugar, unit: "g"),
                .init(label: "나트륨", value: totalSodium, unit: "mg")
            ]
        }
        
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
        case chartAreaTapped
        case presentAnalyzeAddDietSheet
        case binding(BindingAction<State>)
        case delegate(DelegateAction)
        case analyzeAddDietAction(PresentationAction<AnalyzeAddDietFeature.Action>)
        case dismissSheet
    }
    
    enum DelegateAction {
        case navigateToMyPage
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .chartAreaTapped:
                state.isExpanded.toggle()
                return .none
                
            case .presentAnalyzeAddDietSheet:
                state.analyzeAddDietSheet = AnalyzeAddDietFeature.State()
                return .none
                
            case .analyzeAddDietAction(.presented(.delegate(.dismissSheet))):
                return .send(.dismissSheet)
                
            case .analyzeAddDietAction(.presented(.delegate(.addDiets(let diets)))):
                state.selectedDiets.append(contentsOf: diets)
                return .run { send in
                    await send(.dismissSheet)
                }
                
            case .dismissSheet:
                state.analyzeAddDietSheet = nil
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
