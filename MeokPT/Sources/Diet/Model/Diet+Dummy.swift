import Foundation

extension Diet {
    static var dummy: Diet {
        let foods: [Food] = [
            Food(name: "사과", amount: 100, kcal: 52, carbohydrate: 14, protein: 0.3, fat: 0.2, dietaryFiber: 2.4, sodium: 1, sugar: 10),
            Food(name: "닭가슴살", amount: 150, kcal: 248, carbohydrate: 0, protein: 50, fat: 4.5, dietaryFiber: 0, sodium: 110, sugar: 0),
            Food(name: "현미밥", amount: 200, kcal: 260, carbohydrate: 56, protein: 5, fat: 2, dietaryFiber: 3.6, sodium: 10, sugar: 0)
        ]
        return Diet(title: "건강식단", isFavorite: false, foods: foods)
    }
    
    static var dummys: [Diet] {
        [
            Diet(
                title: "아침",
                isFavorite: true,
                foods: [
                    Food(name: "계란후라이", amount: 100, kcal: 199, carbohydrate: 1.5, protein: 13, fat: 15, dietaryFiber: 0, sodium: 200, sugar: 1),
                    Food(name: "베이컨", amount: 50, kcal: 270, carbohydrate: 0.5, protein: 7, fat: 27, dietaryFiber: 0, sodium: 800, sugar: 0),
                    Food(name: "식빵", amount: 50, kcal: 133, carbohydrate: 25, protein: 4, fat: 2, dietaryFiber: 1.5, sodium: 250, sugar: 2.5)
                ]
            ),
            Diet(
                title: "점심",
                isFavorite: false,
                foods: [
                    Food(name: "소고기", amount: 200, kcal: 516, carbohydrate: 0, protein: 52, fat: 34, dietaryFiber: 0, sodium: 140, sugar: 0),
                    Food(name: "상추", amount: 50, kcal: 8, carbohydrate: 1.4, protein: 0.7, fat: 0.1, dietaryFiber: 0.7, sodium: 4, sugar: 0.4),
                    Food(name: "된장찌개", amount: 200, kcal: 198, carbohydrate: 10, protein: 12, fat: 12, dietaryFiber: 4, sodium: 1200, sugar: 2)
                ]
            ),
            Diet(
                title: "저녁",
                isFavorite: true,
                foods: [
                    Food(name: "고등어구이", amount: 150, kcal: 468, carbohydrate: 0, protein: 36, fat: 36, dietaryFiber: 0, sodium: 250, sugar: 0),
                    Food(name: "김치", amount: 50, kcal: 15, carbohydrate: 2.5, protein: 1, fat: 0.2, dietaryFiber: 1.4, sodium: 330, sugar: 1)
                ]
            )
        ]
    }
}
