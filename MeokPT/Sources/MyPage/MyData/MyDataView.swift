//
//  MyDataView.swift
//  MeokPT
//
//  Created by 김동영 on 7/18/25.
//

import SwiftUI
import ComposableArchitecture

struct MyDataView: View {
    @FocusState private var focusedNutrientField: NutrientField?
    @FocusState private var focusedBodyField: BodyField?
    @Bindable var store: StoreOf<MyDataFeature>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 36) {
                    HStack {
                        Text("목표 섭취량")
                            .font(.title2.bold())
                        Spacer()
                        Picker("목표 섭취량 계산 방식", selection: $store.selectedAutoOrCustomFilter) {
                            ForEach(AutoOrCustomFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .fixedSize()
                    }
                    // 신체 정보 입력
                    VStack(spacing: 24) {
                        HStack {
                            Text("신체 정보")
                                .font(.title2.bold())
                            Spacer()
                        }
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
                                focus: .heightField,
                                focusedField: $focusedBodyField
                            )
                            UnitTextField(
                                title: "나이",
                                unit: " 세",
                                text: $store.myAge,
                                focus: .ageField,
                                focusedField: $focusedBodyField
                            )
                            UnitTextField(
                                title: "체중",
                                unit: " kg",
                                text: $store.myWeight,
                                focus: .weightField,
                                focusedField: $focusedBodyField
                            )
                        }
                    }
                    
                    Divider().padding(.horizontal, -24)
                    
                    // 식단 목표 선택
                    VStack(spacing: 24) {
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
                    
                    Divider().padding(.horizontal, -24)

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
                focusedBodyField = nil
            }
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedBodyField != nil {
                        Spacer()
                        Button(focusedBodyField == .weightField ? "완료" : "다음") {
                            switch focusedBodyField {
                            case .heightField:
                                focusedBodyField = .ageField
                            case .ageField:
                                focusedBodyField = .weightField
                            case .weightField:
                                focusedBodyField = nil
                            case .none:
                                break
                            }
                        }
                    }
                }
            }
            .navigationTitle("목표 섭취량 설정")
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
