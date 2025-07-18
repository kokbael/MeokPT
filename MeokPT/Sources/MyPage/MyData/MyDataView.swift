//
//  MyDataView.swift
//  MeokPT
//
//  Created by 김동영 on 7/18/25.
//

import SwiftUI
import ComposableArchitecture

struct MyDataView: View {
    enum Field: Hashable {
        case myHeight, myAge, myWeight
    }
    @FocusState private var focusedField: Field?
    @Bindable var store: StoreOf<MyDataFeature>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 48) {
                    // 성별 선택
                    Picker("성별", selection: $store.selectedGenderFilter) {
                        ForEach(GenderFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    HStack(spacing: 36) {
                        UnitTextField(
                            title: "신장",
                            unit: " cm",
                            text: $store.myHeight,
                            focus: .myHeight,
                            focusedField: $focusedField
                        )
                        UnitTextField(
                            title: "나이",
                            unit: " 세",
                            text: $store.myAge,
                            focus: .myAge,
                            focusedField: $focusedField
                        )
                        UnitTextField(
                            title: "체중",
                            unit: " kg",
                            text: $store.myWeight,
                            focus: .myWeight,
                            focusedField: $focusedField
                        )
                    }

                    // 식단 목표 선택
                    VStack {
                        HStack {
                            Text("식단 목표")
                                .font(.title2.bold())
                            Spacer()
                        }
                        Picker("식단 목표", selection: $store.selectedTargetFilter) {
                            ForEach(TargetFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 활동량 선택
                    HStack {
                        Text("활동량")
                            .font(.title2.bold())
                        Spacer()
                        Button(action: {
                            store.send(.presentActivityLevelSheet)
                        }) {
                            HStack {
                                Text("활동량 선택하기")
                                Image(systemName: "chevron.up")
                            }
                        }
                    }
                }
                .padding(24)
            }
            .onTapGesture {
                focusedField = nil
            }
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItemGroup(placement: .principal) {
                    Picker("정렬", selection: $store.selectedViewFilter) {
                        ForEach(ViewFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedField != nil {
                        Spacer()
                        Button(focusedField == .myWeight ? "완료" : "다음") {
                            switch focusedField {
                            case .myHeight:
                                focusedField = .myAge
                            case .myAge:
                                focusedField = .myWeight
                            case .myWeight:
                                focusedField = nil
                            case .none:
                                break
                            }
                        }
                    }
                }
            }
            .navigationTitle("내 정보 입력")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color("AppBackgroundColor"))
            .sheet(item: $store.scope(state: \.activityLevelSheet, action: \.activityLevelSheetAction)) { store in
                NavigationStack {
                    ActivityLevelView(store: store)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.medium])
                }
            }
        }
        .onAppear {
            
        }
        .tint(Color("TextButton"))
    }
}

#Preview {
    MyDataView(
        store: Store(initialState: MyDataFeature.State()) {
            MyDataFeature()
        }
    )
}
