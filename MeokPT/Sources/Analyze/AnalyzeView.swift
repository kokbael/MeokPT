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
                VStack(alignment: .leading, spacing: 16) {
                    // "열량" 차트를 조건문 밖으로 이동시켜 깜빡임 방지
                    if let caloriesItem = item(for: "열량") {
                        ChartView(
                            nutrient: caloriesItem.nutrient,
                            maxValue: caloriesItem.maxValue,
                            barColor: caloriesItem.barColor,
                            showValues: store.isExpanded
                        )
                    }

                    if store.isExpanded {
                        // Expanded: "열량"을 제외한 나머지 6개 항목
                        ForEach(store.analyzeItems.filter { $0.nutrient.label != "열량" }) { item in
                            ChartView(
                                nutrient: item.nutrient,
                                maxValue: item.maxValue,
                                barColor: item.barColor,
                                showValues: true
                            )
                        }
                    } else {
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
                .onTapGesture {
                    store.send(.chartAreaTapped)
                }
                // --- 애니메이션 효과 옵션 --- 
                // .easeIn: 천천히 시작
                // .easeOut: 천천히 끝남
                // .easeInOut: 천천히 시작하고 천천히 끝남 (기본값 중 하나)
                // .linear: 일정한 속도
                // .spring: 용수철처럼 통통 튀는 효과 (duration, bounce 등 파라미터 조절 가능)
                .animation(.linear(duration: 0.3), value: store.isExpanded)
            }
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
                        Text(String(format: "%.0f %@", nutrient.value, nutrient.unit))
                            .foregroundStyle(.primary).bold()
                        Text("/")
                        Text(String(format: "%.0f %@", maxValue, nutrient.unit))
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
                        Text(String(format: "%.0f %@", nutrient.value, nutrient.unit))
                            .foregroundStyle(.primary).bold()
                        Text("/")
                        Text(String(format: "%.0f %@", maxValue, nutrient.unit))
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
                .animation(.spring(), value: nutrient.value)
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
