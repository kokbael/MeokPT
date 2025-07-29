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
            ScrollViewReader { proxy in
                ScrollView {
                    Color.clear.frame(height: 0).id("topAnchor")
                    VStack(spacing: 36) {
                        VStack(spacing: 24) {
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
                            
                            // 영양성분 입력
                            VStack(spacing: 8) {
                                Spacer()
                                NutrientRow(label: "열량", unit: "kcal", value: $store.myKcal, focus: .kcal, focusedField: $focusedNutrientField)
                                Divider()
                                NutrientRow(label: "탄수화물", unit: "g", value: $store.myCarbohydrate, focus: .carbohydrate, focusedField: $focusedNutrientField)
                                Divider()
                                NutrientRow(label: "단백질", unit: "g", value: $store.myProtein, focus: .protein, focusedField: $focusedNutrientField)
                                Divider()
                                NutrientRow(label: "지방", unit: "g", value: $store.myFat, focus: .fat, focusedField: $focusedNutrientField)
                                Divider()
                                NutrientRow(label: "식이섬유", unit: "g", value: $store.myDietaryFiber, focus: .dietaryFiber, focusedField: $focusedNutrientField)
                                Divider()
                                NutrientRow(label: "당류", unit: "g", value: $store.mySugar, focus: .sugar, focusedField: $focusedNutrientField)
                                Divider()
                                NutrientRow(label: "나트륨", unit: "mg", value: $store.mySodium, focus: .sodium, focusedField: $focusedNutrientField)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(UIColor.separator), lineWidth: 1)
                            )
                            .disabled(store.selectedAutoOrCustomFilter == .auto)
                        }

                        if store.selectedAutoOrCustomFilter == .auto {
                            Text("정보를 입력하면 목표 섭취량을 자동 계산합니다.")
                            Divider().padding(.horizontal, -24)
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
                            
                            Divider().padding(.horizontal, -24)
                            
                            Text("목표 섭취량은 미플린-세인트 지어(Mifflin-St Jeor) 공식을 사용하여 기초대사량(BMR)을 계산하고, 이를 바탕으로 개인의 목표와 활동대사량(TDEE)에 맞춰 설정됩니다.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, -16)
                        }
                    }
                    .padding(24)
                }
                .onTapGesture {
                    focusedNutrientField = nil
                    focusedBodyField = nil
                }
                .scrollDismissesKeyboard(.immediately)
                .onChange(of: store.scrollToTopID) {
                    withAnimation {
                        proxy.scrollTo("topAnchor", anchor: .top)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedNutrientField != nil {
                        Spacer()
                        Button(focusedNutrientField == .sodium ? "완료" : "다음") {
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
                                focusedNutrientField = .sugar
                            case .sugar:
                                focusedNutrientField = .sodium
                            case .sodium:
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

// MARK: - Nutrient Input Row View
private struct NutrientRow: View {
    let label: String
    let unit: String
    @Binding var value: Double?
    let focus: NutrientField
    @FocusState.Binding var focusedField: NutrientField?

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(Color("AppSecondaryColor"))
                .font(.body)
                .frame(width: 70, alignment: .leading)
            
            Spacer()

            NutrientTextField(
                unit: unit,
                value: $value,
                focus: focus,
                focusedField: $focusedField
            )
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Nutrient Text Field
private struct NutrientTextField: View {
    let unit: String
    @Binding var value: Double?
    let focus: NutrientField
    @FocusState.Binding var focusedField: NutrientField?

    private var textValue: Binding<String> {
        Binding<String>(
            get: {
                guard let value = value else { return "" }
                // 소수점 아래 값이 0이면 정수로, 아니면 소수점 첫째 자리까지 표시
                return value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value)
            },
            set: {
                value = Double($0)
            }
        )
    }

    var body: some View {
        HStack(spacing: 4) {
            TextField("0", text: textValue)
                .focused($focusedField, equals: focus)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 50)
            
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .center)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = focus
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
