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
                                Picker("목표 섭취량 계산 방식", selection: $store.selectedAutoOrCustomFilter.animation()) {
                                    ForEach(AutoOrCustomFilter.allCases) { filter in
                                        Text(filter.rawValue).tag(filter)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .fixedSize()
                            }
                            
                            // 영양성분 입력
                            VStack(spacing: 8) {
                                NutrientRow(label: "열량", unit: "kcal", autoOrCustom: store.selectedAutoOrCustomFilter, text: $store.customKcal, displayValue: store.myKcal, focus: .kcal, focusedField: $focusedNutrientField)
                                Divider()
                                NutrientRow(label: "탄수화물", unit: "g", autoOrCustom: store.selectedAutoOrCustomFilter, text: $store.customCarbohydrate, displayValue: store.myCarbohydrate, focus: .carbohydrate, focusedField: $focusedNutrientField)
                                Divider()
                                NutrientRow(label: "단백질", unit: "g", autoOrCustom: store.selectedAutoOrCustomFilter, text: $store.customProtein, displayValue: store.myProtein, focus: .protein, focusedField: $focusedNutrientField)
                                Divider()
                                NutrientRow(label: "지방", unit: "g", autoOrCustom: store.selectedAutoOrCustomFilter, text: $store.customFat, displayValue: store.myFat, focus: .fat, focusedField: $focusedNutrientField)
                                Divider()
                                NutrientRow(label: "식이섬유", unit: "g", autoOrCustom: store.selectedAutoOrCustomFilter, text: $store.customDietaryFiber, displayValue: store.myDietaryFiber, focus: .dietaryFiber, focusedField: $focusedNutrientField)
                                Divider()
                                NutrientRow(label: "당류", unit: "g", autoOrCustom: store.selectedAutoOrCustomFilter, text: $store.customSugar, displayValue: store.mySugar, focus: .sugar, focusedField: $focusedNutrientField)
                                Divider()
                                NutrientRow(label: "나트륨", unit: "mg", autoOrCustom: store.selectedAutoOrCustomFilter, text: $store.customSodium, displayValue: store.mySodium, focus: .sodium, focusedField: $focusedNutrientField)
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(UIColor.separator), lineWidth: 1)
                            )
                        }

                        if store.selectedAutoOrCustomFilter == .custom {
                            // 저장 버튼
                            Button(action: {
                                store.send(.saveCustomNutrientsTapped)
                            }) {
                                Text("저장하기")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color("AppTintColor"))
                                    .cornerRadius(30)
                            }
                            .font(.headline.bold())
                            .foregroundStyle(.black)
                            .buttonStyle(PlainButtonStyle())
                            .contentShape(Rectangle())
                            .disabled(store.isCustomSaveButtonDisabled)
                        }
                        else {
                            Divider().padding(.horizontal, -24)
                                .id("bottomAnchor")
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
                                // 신장, 나이, 체중 입력
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
                            
                            Button(action: {
                                store.send(.updateNutrientsTapped)
                            }) {
                                Text("목표 섭취량 업데이트")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color("AppTintColor"))
                                    .cornerRadius(30)
                            }
                            .font(.headline.bold())
                            .foregroundStyle(.black)
                            .buttonStyle(PlainButtonStyle())
                            .contentShape(Rectangle())
                            .disabled(store.isUpdateNutrientDisabled)
                            
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
                    withAnimation(.easeInOut(duration: 0.7)) {
                        proxy.scrollTo("topAnchor", anchor: .top)
                    }
                }
                .onChange(of: store.scrollToBottomID) {
                    Task {
                        try? await Task.sleep(for: .milliseconds(100))
                        withAnimation(.easeInOut(duration: 0.7)) {
                            proxy.scrollTo("bottomAnchor", anchor: .top)
                        }
                    }
                }
                // 1. TCA Store의 상태가 바뀌면 -> 뷰의 @FocusState를 업데이트
                .onChange(of: store.focusedNutrientField) { _, newValue in
                    focusedNutrientField = newValue
                }
                // 2. 뷰의 @FocusState가 바뀌면 (사용자가 TextField를 탭하면) -> TCA Store의 상태를 업데이트
                .onChange(of: focusedNutrientField) { _, newValue in
                    store.send(.binding(.set(\.focusedNutrientField, newValue)))
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
    let autoOrCustom: AutoOrCustomFilter
    @Binding var text: String
    let displayValue: Double?
    let focus: NutrientField
    @FocusState.Binding var focusedField: NutrientField?
    
    var isCustomMode: Bool {
        autoOrCustom == .custom
    }
    
    // 자동 계산된 영양성분 포맷팅
    var formattedValue: String {
        guard let value = displayValue else { return "0" }
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(Color("AppSecondaryColor"))
                .font(.body)
                .frame(width: 70, alignment: .leading)
            
            Spacer()
            
            if isCustomMode {
                HStack(spacing: 4) {
                    // 자동 계산된 값을 플레이스홀더로 사용
                    TextField(formattedValue, text: $text)
                        .focused($focusedField, equals: focus)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 50)
                    
                    Text(unit)
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .center)
                }
                .onTapGesture {
                    focusedField = focus
                }
            } else {
                HStack(spacing: 4) {
                    Text(formattedValue)
                        .font(.body.bold())
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 50, alignment: .trailing)
                    
                    Text(unit)
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .center)
                }
            }
        }
        .frame(minHeight: 44)
    }
}

#Preview {
    MyDataView(
        store: Store(initialState: MyDataFeature.State()) {
            MyDataFeature()
        }
    )
}
