import SwiftUI

struct UnitTextField: View {
    let title: String
    let unit: String
    @Binding var text: String
    let focus: BodyField
    @FocusState.Binding var focusedField: BodyField?

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // 플레이스홀더가 투명해져도(opacity(0)) 공간을 차지하게 만들어
                // ZStack의 최소 너비를 보장하고 레이아웃 오류를 방지합니다.
                Text(title)
                    .foregroundStyle(Color(.placeholderText))
                    .allowsHitTesting(false)
                    .opacity(text.isEmpty ? 1 : 0)

                HStack(spacing: 0) {
                    TextField("", text: $text)
                        .focused($focusedField, equals: focus)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(text.isEmpty ? .center : .trailing)
                        .fixedSize()
                    
                    if !text.isEmpty {
                        Text(unit)
                    }
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = focus
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color(.placeholderText))
        }
    }
}

