//
//  AnalyzeAddDietFeature.swift
//  MeokPT
//
//  Created by 김동영 on 7/5/25.
//

import ComposableArchitecture
import Foundation
import SwiftData

@Reducer
struct AnalyzeAddDietFeature {
    
    @ObservableState
    struct State: Equatable, Hashable {
        var title: String = ""
        var content: String = ""
        
        var dietList: IdentifiedArrayOf<Diet> = []
        var selectedFilter: DietFilter = .dateDescending
        var isFavoriteFilterActive: Bool = false
        var searchText: String = ""
        
        var currentDietList: [Diet] {
            let searchedDiets = searchText.isEmpty ? dietList.elements : dietList.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
            let favoriteFilteredDiets = isFavoriteFilterActive ? searchedDiets.filter { $0.isFavorite } : searchedDiets
            
            switch selectedFilter {
            case .dateDescending:
                return favoriteFilteredDiets.sorted { $0.creationDate > $1.creationDate }
            case .nameAscending:
                return favoriteFilteredDiets.sorted { $0.title.compare($1.title) == .orderedAscending }
            }
        }
        
        var selectedDietIDs: [UUID] = []
        
    }
    
    enum Action: BindableAction {
        case delegate(DelegateAction)
        case binding(BindingAction<State>)
        case onAppear
        case dietsLoaded([Diet])
        case addButtonTapped
        case favoriteFilterButtonTapped
    }
    
    enum DelegateAction: Equatable {
        case dismissSheet
        case dietsAdded
    }

    
    enum CancelID { case timer }
    
    @Dependency(\.modelContainer) var modelContainer
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await MainActor.run {
                        do {
                            let context = modelContainer.mainContext
                            let descriptor = FetchDescriptor<Diet>(sortBy: [SortDescriptor(\.title)])
                            let diets = try context.fetch(descriptor)
                            send(.dietsLoaded(diets))
                        } catch {
                            print("Failed to fetch diets: \(error)")
                            send(.dietsLoaded([]))
                        }
                    }
                }
                
            case let .dietsLoaded(diets):
                state.dietList = IdentifiedArrayOf(uniqueElements: diets)
                return .none
                
            case .addButtonTapped:
                return .run { [selectedDietIDs = state.selectedDietIDs] send in
                    await MainActor.run {
                        do {
                            let context = modelContainer.mainContext
                            
                            // Determine the starting order index
                            let countDescriptor = FetchDescriptor<AnalysisSelection>()
                            let currentCount = try context.fetchCount(countDescriptor)
                            
                            for (index, dietID) in selectedDietIDs.enumerated() {
                                let selection = AnalysisSelection(dietID: dietID, orderIndex: currentCount + index)
                                context.insert(selection)
                            }
                            try context.save()
                        } catch {
                            print("Failed to save diet selections: \(error)")
                        }
                    }
                    await send(.delegate(.dietsAdded))
                }
                
            case .favoriteFilterButtonTapped:
                state.isFavoriteFilterActive.toggle()
                return .none
                
            case .binding(_):
                return .none
            case .delegate(_):
                return .none

            }
        }
    }
}

