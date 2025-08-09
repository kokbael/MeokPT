import SwiftUI
import ComposableArchitecture
import SwiftData

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
    
    init(selectionID: UUID, diet: Diet) {
        self.id = selectionID
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
        
        var maxValues: [String: Double] = [:]
        
        var analyzeItems: [AnalyzeData] {
            currentNutrients.map { nutrient in
                // 1. maxValue 계산 (목표량이 설정되지 않았으면 0으로 처리)
                let maxValue = maxValues[nutrient.label] ?? 0
                
                // 2. barColor 계산 (0으로 나누기 방지)
                let percentage = (maxValue > 0) ? (nutrient.value / maxValue) : 0
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
        var isEditing: Bool = false
        var draggedDiet: SelectedDiet?
        
        var isTargetNutrientSet: Bool {
            !maxValues.isEmpty && maxValues.values.reduce(0, +) > 0
        }
    }
    
    enum Action: BindableAction {
        case onAppear
        case chartAreaTapped
        case presentAnalyzeAddDietSheet
        case binding(BindingAction<State>)
        case delegate(DelegateAction)
        case analyzeAddDietAction(PresentationAction<AnalyzeAddDietFeature.Action>)
        case dismissSheet
        case loadData
        case dietsLoaded([SelectedDiet])
        case targetNutrientLoaded(TargetNutrient?)
        case editButtonTapped
        case deleteButtonTapped(id: UUID)
        case setDraggedDiet(SelectedDiet?)
        case moveDiet(from: UUID, to: UUID)
        case goToMyPageButtonTapped
    }
    
    enum DelegateAction {
        case navigateToMyPage
    }
    
    @Dependency(\.modelContainer) var modelContainer

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadData)
                
            case .chartAreaTapped:
                state.isExpanded.toggle()
                return .none
                
            case .presentAnalyzeAddDietSheet:
                state.analyzeAddDietSheet = AnalyzeAddDietFeature.State()
                return .none
                
            case .analyzeAddDietAction(.presented(.delegate(.dismissSheet))):
                return .send(.dismissSheet)
                
            case .analyzeAddDietAction(.presented(.delegate(.dietsAdded))):
                return .run { send in
                    await send(.dismissSheet)
                    await send(.loadData)
                }
                
            case .dismissSheet:
                state.analyzeAddDietSheet = nil
                return .none
                
            case .loadData:
                return .run { send in
                    await MainActor.run {
                        do {
                            let context = modelContainer.mainContext
                            
                            // Load Selected Diets
                            let selectionDescriptor = FetchDescriptor<AnalysisSelection>(sortBy: [SortDescriptor(\.orderIndex)])
                            let selections = try context.fetch(selectionDescriptor)
                            
                            let dietDescriptor = FetchDescriptor<Diet>()
                            let allDiets = try context.fetch(dietDescriptor)
                            
                            let selectedDiets = selections.compactMap { selection -> SelectedDiet? in
                                if let diet = allDiets.first(where: { $0.id == selection.dietID }) {
                                    return SelectedDiet(selectionID: selection.id, diet: diet)
                                }
                                return nil
                            }
                            send(.dietsLoaded(selectedDiets))
                            
                            // Load Target Nutrient
                            let targetNutrientDescriptor = FetchDescriptor<TargetNutrient>()
                            let targetNutrient = try context.fetch(targetNutrientDescriptor).first
                            send(.targetNutrientLoaded(targetNutrient))
                            
                        } catch {
                            print("Failed to load data: \(error)")
                        }
                    }
                }
                
            case let .dietsLoaded(diets):
                state.selectedDiets = diets
                return .none
                
            case let .targetNutrientLoaded(targetNutrient):
                if let nutrient = targetNutrient {
                    state.maxValues["열량"] = nutrient.myKcal
                    state.maxValues["탄수화물"] = nutrient.myCarbohydrate
                    state.maxValues["단백질"] = nutrient.myProtein
                    state.maxValues["지방"] = nutrient.myFat
                    state.maxValues["식이섬유"] = nutrient.myDietaryFiber
                    state.maxValues["당류"] = nutrient.mySugar
                    state.maxValues["나트륨"] = nutrient.mySodium
                }
                return .none
                
            case .editButtonTapped:
                state.isEditing.toggle()
                if !state.isEditing {
                    state.draggedDiet = nil
                }
                return .none
                
            case let .deleteButtonTapped(id):
                state.selectedDiets.removeAll { $0.id == id }
                return .run { send in
                    await MainActor.run {
                        do {
                            let context = modelContainer.mainContext
                            let descriptor = FetchDescriptor<AnalysisSelection>(
                                predicate: #Predicate { $0.id == id }
                            )
                            if let selectionToDelete = try context.fetch(descriptor).first {
                                context.delete(selectionToDelete)
                                try context.save()
                            }
                        } catch {
                            print("Failed to delete diet selection: \(error)")
                        }
                    }
                }
                
            case let .setDraggedDiet(diet):
                state.draggedDiet = diet
                return .none
                
            case let .moveDiet(from: fromID, to: toID):
                guard let fromIndex = state.selectedDiets.firstIndex(where: { $0.id == fromID }),
                      let toIndex = state.selectedDiets.firstIndex(where: { $0.id == toID }) else {
                    return .none
                }
                state.selectedDiets.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                state.draggedDiet = nil // 드롭 직후 드래그 상태 초기화
                
                return .run { [selectedDiets = state.selectedDiets] send in
                    await MainActor.run {
                        do {
                            let context = modelContainer.mainContext
                            for (index, diet) in selectedDiets.enumerated() {
                                let selectionID = diet.id
                                let descriptor = FetchDescriptor<AnalysisSelection>(predicate: #Predicate { $0.id == selectionID })
                                if let selectionToUpdate = try context.fetch(descriptor).first {
                                    selectionToUpdate.orderIndex = index
                                }
                            }
                            try context.save()
                        } catch {
                            print("Failed to save new order: \(error)")
                        }
                    }
                    await send(.loadData)
                }
                
            case .goToMyPageButtonTapped:
                return .send(.delegate(.navigateToMyPage))
                
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
