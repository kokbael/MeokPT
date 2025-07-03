import SwiftUI
import ComposableArchitecture

struct AnalyzeView: View {
    @Bindable var store: StoreOf<AnalyzeFeature>

    var body: some View {
        NavigationStack {
            Text("Analyze")
        }
    }
}

#Preview {
    AnalyzeView(store: Store(initialState: AnalyzeFeature.State()) {
        AnalyzeFeature()
    })
}
