import ComposableArchitecture
import Foundation

@Reducer
struct AnalyzeFeature {
    @ObservableState
    struct State: Equatable {

    }
    
    enum Action: Equatable {
        case delegate(DelegateAction)
        
    }
    
    enum DelegateAction {
        case navigateToMyPage
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .delegate(_):
                return .none
            }
        }
        
    }
}
