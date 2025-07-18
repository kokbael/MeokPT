//
//  ActivityLevelView.swift
//  MeokPT
//
//  Created by 김동영 on 7/19/25.
//

import SwiftUI
import ComposableArchitecture

struct ActivityLevelView: View {
    @Bindable var store: StoreOf<ActivityLevelFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(ActivityLevel.allCases) { level in
                    VStack(alignment: .center, spacing: 8) {
                        Text(level.title)
                            .font(.title3.bold())
                        
                        Text(level.description)
                            .multilineTextAlignment(.center)
                            .frame(minHeight: 50)
                    }
                    .frame(height: 130)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(UIColor.secondarySystemGroupedBackground)
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(UIColor.separator), lineWidth: 1)
                    )
                    .onTapGesture {
                        
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("활동량 선택")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color("AppBackgroundColor"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    store.send(.delegate(.dismissSheet))
                } label: {
                    Text("취소")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ActivityLevelView(store: Store(initialState: ActivityLevelFeature.State()) {
            ActivityLevelFeature()
        })
    }
}
