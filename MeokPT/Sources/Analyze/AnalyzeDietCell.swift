//
//  AnalyzeDietCell.swift
//  MeokPT
//
//  Created by 김동영 on 7/5/25.
//

import SwiftUI

struct AnalyzeDietCell: View {
    var diet: Diet
    var isSelected: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading) {
                HStack(spacing: 16) {
                    Text(diet.title)
                        .font(.title3.bold())
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundStyle(Color("AppSecondaryColor"))
                }
                Spacer().frame(height: 4)
                if (diet.foods.isEmpty) {
                    Text("--- kcal")
                } else {
                    Text("\(diet.kcal.formattedWithSeparator) kcal")
                        .font(.body)
                }
            }
            Spacer().frame(height: 8)
            HStack {
                if (diet.foods.isEmpty) {
                    EmptyNutrientView()
                } else {
                    NutrientView(carbohydrate: diet.carbohydrate, protein: diet.protein, fat: diet.fat)
                }
            }
        }
        .padding(24)
        .background(isSelected ? Color("AppSecondaryColor").opacity(0.2) : Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(uiColor: UIColor.separator), lineWidth: 1)
        )
    }
}
