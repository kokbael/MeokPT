import ComposableArchitecture
import SwiftData
import Foundation

// ModelContainer를 의존성으로 주입
private enum ModelContainerKey: DependencyKey {
    static let schema = Schema([
        Diet.self,
        Food.self,
        SharedPostRecord.self,
        AnalysisSelection.self,
        MyData.self,
        TargetNutrient.self,
    ])
    
    static var liveValue: ModelContainer {
        do {
            return try ModelContainer(
                for: schema
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    static var testValue: ModelContainer {
        do {
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        } catch {
            fatalError("Failed to create test ModelContainer: \(error.localizedDescription)")
        }
    }
}

extension DependencyValues {
    var modelContainer: ModelContainer {
        get { self[ModelContainerKey.self] }
        set { self[ModelContainerKey.self] = newValue }
    }
}
