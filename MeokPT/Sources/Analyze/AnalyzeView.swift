import SwiftUI
import ComposableArchitecture

struct AnalyzeView: View {
    @Bindable var store: StoreOf<AnalyzeFeature>

    // Helper to find a specific item by its label
    private func item(for label: String) -> AnalyzeData? {
        store.analyzeItems.first { $0.nutrient.label == label }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // --- 차트 섹션 ---
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("영양성분")
                                .font(.title2.bold())
                            Spacer()
                            Button(action: {
                                store.send(.chartAreaTapped)
                            }) {
                                !store.isExpanded ? Text("자세히") : Text("간단히")
                                    .foregroundStyle(Color("TextButton"))
                            }
                        }
                        // "열량" 차트
                        if let caloriesItem = item(for: "열량") {
                            ChartView(
                                nutrient: caloriesItem.nutrient,
                                maxValue: caloriesItem.maxValue,
                                barColor: caloriesItem.barColor,
                                showValues: store.isExpanded
                            )
                        }
                        if store.isExpanded {
                            // 나머지 6개 항목
                            ForEach(store.analyzeItems.filter { $0.nutrient.label != "열량" }) { item in
                                ChartView(
                                    nutrient: item.nutrient,
                                    maxValue: item.maxValue,
                                    barColor: item.barColor,
                                    showValues: true
                                )
                            }
                        } else {
                            // 요약된 3x2 그리드
                            HStack(spacing: 16) {
                                if let carbsItem = item(for: "탄수화물") {
                                    ChartView(
                                        nutrient: carbsItem.nutrient,
                                        maxValue: carbsItem.maxValue,
                                        barColor: carbsItem.barColor,
                                        showValues: false
                                    )
                                }
                                if let proteinItem = item(for: "단백질") {
                                    ChartView(
                                        nutrient: proteinItem.nutrient,
                                        maxValue: proteinItem.maxValue,
                                        barColor: proteinItem.barColor,
                                        showValues: false
                                    )
                                }
                                if let fatItem = item(for: "지방") {
                                    ChartView(
                                        nutrient: fatItem.nutrient,
                                        maxValue: fatItem.maxValue,
                                        barColor: fatItem.barColor,
                                        showValues: false
                                    )
                                }
                            }
                            HStack(spacing: 16) {
                                if let fiberItem = item(for: "식이섬유") {
                                    ChartView(
                                        nutrient: fiberItem.nutrient,
                                        maxValue: fiberItem.maxValue,
                                        barColor: fiberItem.barColor,
                                        showValues: false
                                    )
                                }
                                if let sugarItem = item(for: "당류") {
                                    ChartView(
                                        nutrient: sugarItem.nutrient,
                                        maxValue: sugarItem.maxValue,
                                        barColor: sugarItem.barColor,
                                        showValues: false
                                    )
                                }
                                if let sodiumItem = item(for: "나트륨") {
                                    ChartView(
                                        nutrient: sodiumItem.nutrient,
                                        maxValue: sodiumItem.maxValue,
                                        barColor: sodiumItem.barColor,
                                        showValues: false
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .animation(.spring(duration: 0.5), value: store.isExpanded)
                    
                    
                    // --- 선택된 식단 리스트 ---
                    if !store.selectedDiets.isEmpty {
                        VStack(spacing: 0) {
                            HStack {
                                Text("선택된 식단")
                                    .font(.title2.bold())
                                Spacer()
                                Button(store.isEditing ? "완료" : "편집") {
                                    store.send(.editButtonTapped)
                                }
                                .foregroundStyle(Color("TextButton"))
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 12)

                            ForEach(store.selectedDiets) { entry in
                                HStack(spacing: 12) {
                                    if store.isEditing {
                                        // 삭제 버튼
                                        Button(action: {
                                            if let index = store.selectedDiets.firstIndex(where: { $0.id == entry.id }) {
                                                store.send(.delete(at: IndexSet(integer: index)))
                                            }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.title2)
                                        }
                                    }

                                    AnalyzeSelectedDietCell(diet: entry.diet)
                                        .opacity(store.draggedDiet?.id == entry.id ? 0.5 : 1.0)
                                        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 20))
                                        .onDrag {
                                            if store.isEditing {
                                                store.send(.setDraggedDiet(entry))
                                                return NSItemProvider(object: entry.id.uuidString as NSString)
                                            }
                                            return NSItemProvider()
                                        }
                                        .wiggle(isWiggling: store.isEditing)
                                }
                                .onDrop(of: [.text], delegate: DietDropDelegate(item: entry, draggedItem: $store.draggedDiet, store: store))
                                .padding(.horizontal, 24)
                                .padding(.bottom, 12)
                                .animation(.default, value: store.isEditing)
                                .animation(.default, value: store.draggedDiet)
                            }
                        }
                        .background(Color("AppBackgroundColor"))
                    }
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
            .background(Color("AppBackgroundColor"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button (action: {
                        store.send(.presentAnalyzeAddDietSheet)
                    }) {
                        Image(systemName: "plus")
                            .foregroundStyle(Color("AppSecondaryColor"))
                    }
                }
            }
            .navigationTitle("식단 분석")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color("AppBackgroundColor"))
            .sheet(item: $store.scope(state: \.analyzeAddDietSheet, action: \.analyzeAddDietAction)) { store in
                NavigationStack {
                    AnalyzeAddDietView(store: store)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.large])
                }
            }
        }
        .tint(Color("TextButton"))
    }
}

private struct DietDropDelegate: DropDelegate {
    let item: SelectedDiet
    @Binding var draggedItem: SelectedDiet?
    let store: StoreOf<AnalyzeFeature>

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = self.draggedItem else {
            return false
        }
        
        store.send(.moveDiet(from: draggedItem.id, to: item.id))
        
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

private struct ChartView: View {
    let nutrient: Nutrient
    let maxValue: Double
    let barColor: Color
    let showValues: Bool
    var progress: Double { nutrient.value / maxValue }
    var customAlign: HorizontalAlignment {
        if showValues || nutrient.label == "열량" {
            return .leading
        } else {
            return .center
        }
    }

    var body: some View {
        VStack(alignment: customAlign, spacing: 8) {

            if showValues || nutrient.label == "열량" {
                HStack {
                    Text(nutrient.label).bold()
                    Spacer()
                    HStack {
                        Text("\(nutrient.value.formattedWithSeparator) \(nutrient.unit)")
                            .foregroundStyle(.primary).bold()
                        Text("/")
                        Text("\(maxValue.formattedWithSeparator) \(nutrient.unit)")
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .padding(.horizontal, 8)
            } else {
                VStack {
                    Text(nutrient.label).bold()
                    HStack {
                        Text("\(nutrient.value.formattedWithSeparator) \(nutrient.unit)")
                            .foregroundStyle(.primary).bold()
                        Text("/")
                        Text("\(maxValue.formattedWithSeparator) \(nutrient.unit)")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    .lineLimit(1)
                    .padding(.top, 0.5)
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .padding(.horizontal, 8)
            }

            Rectangle()
                .fill(Color(UIColor.systemGray5))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(barColor.opacity(0.8))
                        .scaleEffect(x: progress, y: 1, anchor: .leading)
                }
                .frame(height: 20)
                .clipped()
                .animation(.spring(duration: 1.0), value: nutrient.value)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}


#Preview {
    AnalyzeView(store: Store(initialState: AnalyzeFeature.State()) {
        AnalyzeFeature()
    })
}
