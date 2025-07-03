import SwiftUI
import ComposableArchitecture

struct AnalyzeView: View {
    @Bindable var store: StoreOf<AnalyzeFeature>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(store.analyzeItems) { analyzedItem in
                        ChartView(
                            nutrient: analyzedItem.nutrient,
                            maxValue: analyzedItem.maxValue,
                            barColor: analyzedItem.barColor
                        )
                    }
                }
                .padding(24)
            }
            .navigationTitle("일일 섭취량 분석")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color("AppBackgroundColor"))
        }
    }
}

private struct ChartView: View {
    let nutrient: Nutrient
    let maxValue: Double
    let barColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(nutrient.label)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0f / %.0f %@", nutrient.value, maxValue, nutrient.unit))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            let progress = nutrient.value / maxValue
            
            Rectangle()
                .fill(Color(UIColor.systemGray5))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(barColor.opacity(0.8))
                        .scaleEffect(x: progress, y: 1, anchor: .leading)
                }
                .frame(height: 20)
                .cornerRadius(5)
                .clipped()
                .animation(.spring(), value: nutrient.value)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}


#Preview {
    AnalyzeView(store: Store(initialState: AnalyzeFeature.State()) {
        AnalyzeFeature()
    })
}
