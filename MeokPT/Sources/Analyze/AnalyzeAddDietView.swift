//
//  AnalyzeAddDietView.swift
//  MeokPT
//
//  Created by 김동영 on 7/5/25.
//

import SwiftUI
import ComposableArchitecture

struct AnalyzeAddDietView: View {
    @Bindable var store: StoreOf<AnalyzeAddDietFeature>
    @State private var selectedDietIDs: [UUID] = []
    
    var body: some View {
        dietList
            .onAppear {
                store.send(.onAppear)
            }
            .navigationTitle("식단 선택")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color("AppBackgroundColor"))
            .searchable(text: $store.searchText, prompt: "검색")
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        store.send(.dismissButtonTapped)
                    } label: {
                        Text("취소").foregroundStyle(Color("TextButton"))
                    }
                }
                ToolbarItemGroup(placement: .principal) {
                    Picker("정렬", selection: $store.selectedFilter) {
                        ForEach(DietFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            store.send(.favoriteFilterButtonTapped)
                        } label: {
                            Image(systemName: store.isFavoriteFilterActive ? "heart.fill" : "heart")
                                .foregroundStyle(Color("TextButton"))
                        }
                        Button {
                            
                        } label: {
                            Text("추가 \(selectedDietIDs.count)")
                                .monospacedDigit()
                                .foregroundStyle(Color("TextButton"))
                        }
                    }
                }
            }
    }
    
    private var dietList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(/*store.currentDietList*/Diet.dummys) { diet in
                    AnalyzeDietCell(diet: diet, isSelected: selectedDietIDs.contains(diet.id))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let index = selectedDietIDs.firstIndex(of: diet.id) {
                                selectedDietIDs.remove(at: index)
                            } else {
                                selectedDietIDs.append(diet.id)
                            }
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
}

#Preview {
    NavigationStack {
        AnalyzeAddDietView(store: Store(initialState: AnalyzeAddDietFeature.State()) {
            AnalyzeAddDietFeature()
        })
    }
}
