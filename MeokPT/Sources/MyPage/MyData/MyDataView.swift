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
                    
                    VStack(spacing: 24) {
                        HStack(spacing: 36) {
                            NutrientTextField(
                                title: "칼로리",
                                unit: "kcal",
                                value: $store.myKcal,
                                focus: .kcal,
                                focusedField: $focusedNutrientField
                            )
                            NutrientTextField(
                                title: "탄수화물",
                                unit: "g",
                                value: $store.myCarbohydrate,
                                focus: .carbohydrate,
                                focusedField: $focusedNutrientField
                            )
                            NutrientTextField(
                                title: "단백질",
                                unit: "g",
                                value: $store.myProtein,
                                focus: .protein,
                                focusedField: $focusedNutrientField
                            )
                        }
                        HStack(spacing: 36) {
                            NutrientTextField(
                                title: "지방",
                                unit: "g",
                                value: $store.myFat,
                                focus: .fat,
                                focusedField: $focusedNutrientField
                            )
                            NutrientTextField(
                                title: "식이섬유",
                                unit: "g",
                                value: $store.myDietaryFiber,
                                focus: .dietaryFiber,
                                focusedField: $focusedNutrientField
                            )
                            NutrientTextField(
                                title: "나트륨",
                                unit: "mg",
                                value: $store.mySodium,
                                focus: .sodium,
                                focusedField: $focusedNutrientField
                            )
                        }
                        HStack {
                            NutrientTextField(
                                title: "당류",
                                unit: "g",
                                value: $store.mySugar,
                                focus: .sugar,
                                focusedField: $focusedNutrientField
                            )
                            Spacer()
                            Spacer()
                        }
                    }
                    .disabled(store.selectedAutoOrCustomFilter == .auto)

                    if store.selectedAutoOrCustomFilter == .auto {
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
                                    Text(store.activityLevelTitle)
                                    Image(systemName: "chevron.up")
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
            .onTapGesture {
                focusedBodyField = nil
                focusedNutrientField = nil
            }
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedNutrientField != nil {
                        Spacer()
                        Button(focusedNutrientField == .sugar ? "완료" : "다음") {
                            switch focusedNutrientField {
                            case .kcal:
                                focusedNutrientField = .carbohydrate
                            case .carbohydrate:
                                focusedNutrientField = .protein
                            case .protein:
                                focusedNutrientField = .fat
                            case .fat:
                                focusedNutrientField = .dietaryFiber
                            case .dietaryFiber:
                                focusedNutrientField = .sodium
                            case .sodium:
                                focusedNutrientField = .sugar
                            case .sugar:
                                focusedNutrientField = nil
                            case .none:
                                break
                            }
                        }
                    }
                    
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

private struct NutrientTextField: View {
    let title: String
    let unit: String
    @Binding var value: Double?
    let focus: NutrientField
    @FocusState.Binding var focusedField: NutrientField?

    private var textValue: Binding<String> {
        Binding<String>(
            get: { value.map { String(format: "%.0f", $0) } ?? "" },
            set: { value = Double($0) }
        )
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Text(title)
                    .foregroundStyle(Color(.placeholderText))
                    .allowsHitTesting(false)
                    .opacity(textValue.wrappedValue.isEmpty ? 1 : 0)

                HStack(spacing: 0) {
                    TextField("", text: textValue)
                        .focused($focusedField, equals: focus)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(textValue.wrappedValue.isEmpty ? .center : .trailing)
                        .fixedSize()
                    
                    if !textValue.wrappedValue.isEmpty {
                        Text(unit)
                    }
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = focus
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color(.placeholderText))
        }
    }
}

#Preview {
    MyDataView(
        store: Store(initialState: MyDataFeature.State()) {
            MyDataFeature()
        }
    )
}
