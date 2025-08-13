import Foundation
import SwiftData

@Model
final class AnalysisSelection {
    @Attribute(.unique) var id: UUID
    var dietID: UUID
    var selectionDate: Date
    var orderIndex: Int

    init(id: UUID = UUID(), dietID: UUID, selectionDate: Date = Date(), orderIndex: Int) {
        self.id = id
        self.dietID = dietID
        self.selectionDate = selectionDate
        self.orderIndex = orderIndex
    }
}
