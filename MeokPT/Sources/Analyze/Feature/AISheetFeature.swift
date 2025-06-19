import ComposableArchitecture
import SwiftData
import Foundation
import FirebaseAI

struct AISheetFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var generatedResponse: String = "AI 분석 결과를 기다리는 중입니다..."
        var isLoading: Bool = false
        var errorMessage: String? = nil
        var encodedData: String = ""
    }

    enum Action: Equatable {
        static func == (lhs: AISheetFeature.Action, rhs: AISheetFeature.Action) -> Bool {
            switch (lhs, rhs) {
            case (.onAppear, .onAppear):
                return true
            case (.aiResponse(let lhsResult), .aiResponse(let rhsResult)):
                switch (lhsResult, rhsResult) {
                case (.success(let lhsString), .success(let rhsString)):
                    return lhsString == rhsString
                case (.failure(let lhsError), .failure(let rhsError)):
                    return lhsError.localizedDescription == rhsError.localizedDescription
                default:
                    return false
                }
            default:
                return false
            }
        }
        
        case onAppear
        case aiResponse(Result<String, Error>)
        case getEncodeData(String)
        case aiAnalyzeSave(String)
        
        case delegate(DelegateAction)
    }
    
    enum DelegateAction {
        case saveAnalyze
    }
    
    @Dependency(\.firebaseAIService) var firebaseAIService
    @Dependency(\.modelContainer) var modelContainer
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            guard !state.isLoading && state.generatedResponse == "AI 분석 결과를 기다리는 중입니다..." else {
                return .none
            }
            state.isLoading = true
            
            return .run { send in
                let encodedData: String = await MainActor.run { () -> String in
                    do {
                        let context = modelContainer.mainContext
                        
                        let nutritionDescriptor = FetchDescriptor<NutritionItem>()
                        let nutritionItems = try context.fetch(nutritionDescriptor)
                        
                        let dietDescriptor = FetchDescriptor<DietItem>()
                        let dietItems = try context.fetch(dietDescriptor)
                        
                        guard let nutritionInputForJSON = createNutritionInputForJSON(
                            userRecommendedIntakeItems: nutritionItems,
                            consumedDiets: dietItems
                        ) else {
                            throw NSError(domain: "DataProcessingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "영양 정보 객체 생성 실패"])
                        }
                        
                        let encoder = JSONEncoder()
                        guard let jsonData = try? encoder.encode(nutritionInputForJSON),
                              let jsonInputString = String(data: jsonData, encoding: .utf8) else {
                            throw NSError(domain: "DataProcessingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "영양 정보 JSON Encoding 실패"])
                        }
                        
                        return jsonInputString
                        
                    } catch {
                        send(.aiResponse(.failure(error)))
                    }
                    
                    return "Empty"
                }
                    
                if encodedData != "Empty" {
                        let prompt = """
                        # AI 영양사: 식단 분석 및 마크다운 조언 생성 가이드

                        ## 1. 최상위 목표 (Primary Goal)
                        당신의 최우선 목표는 아래의 모든 지시사항을 빠짐없이 수행하여, **사용자가 입력한 모든 식사(아침, 점심, 저녁, 간식, 그리고 '그 외')에 대한 개별 분석을 담은 '완전한 형태의 마크다운 리포트'만을 최종적으로 생성하는 것**입니다.

                        ## 2. 기본 역할 (Persona)
                        당신은 사용자의 식단 정보를 분석하고, 영양학적 조언을 제공하는 **친절하고 전문적이며, 항상 사용자를 지지하는 AI 영양사**입니다.

                        ---

                        ## 3. 분석 및 생성 절차 (Mandatory Steps)

                        ### [1단계: 내부 분석] (이 내용은 절대 출력하지 마세요)
                        *   사용자에게 보여주기 전에, **내부적으로만 다음 분석을 완료합니다.**
                            1.  입력된 `(encodedData)`에서 `userProfile`의 `dailyRecommendedIntake`와 `consumedDiets` 데이터를 확인합니다.
                            2.  `consumedDiets` 배열을 확인하여 어떤 식사(아침, 점심, 저녁, 간식, **그리고 '해당없음'**) 데이터가 있는지 파악합니다.

                        ### [2단계: 마크다운 리포트 생성]
                        *   **아래 '출력 가이드라인'에 따라 아침, 점심, 저녁, 간식 순서로 각 식사에 대한 분석 섹션을 반드시 생성합니다.**
                        *   **그 후, '해당없음' 데이터가 있다면 마지막에 '그 외' 섹션을 추가합니다.**

                        ### [3단계: 최종 검토] (이 내용은 절대 출력하지 마세요)
                        *   생성된 리포트에 필수 섹션들이 모두 포함되었는지 최종 점검합니다. 누락된 부분이 있다면 즉시 보완하여 완전한 결과물을 만듭니다.

                        ---

                        ## 4. 최종 출력 규칙 (Final Output Rule)
                        **매우 중요: 사용자인 나에게는 오직 [2단계]에서 생성된 최종 마크다운 리포트 텍스트만을 보여주세요. 당신의 내부 분석 과정이나 최종 검토 내용은 절대로 출력물에 포함시키지 마세요. 출력은 반드시 순수한 마크다운 텍스트로 시작해야 합니다.**

                        ---

                        # AI 영양사: 식단 분석 및 마크다운 조언 생성 가이드

                        ## 1. 최상위 목표 (Primary Goal)
                        당신의 최우선 목표는 아래 지침에 따라, **(1) '하루 식단 총평'으로 시작해서, (2) '개별 식단 분석'이 이어지는 '완전한 형태의 마크다운 리포트'만을 최종적으로 생성하는 것**입니다.

                        ## 2. 기본 역할 (Persona)
                        당신은 사용자의 식단 정보를 분석하고, 영양학적 조언을 제공하는 **친절하고 전문적이며, 항상 사용자를 지지하는 AI 영양사**입니다.

                        ---

                        ## 3. 분석 및 생성 절차 (Mandatory Steps)

                        ### [1단계: 내부 분석] (이 내용은 절대 출력하지 마세요)
                        *   **내부적으로만 다음 분석을 완료합니다.**
                            1.  입력된 `(encodedData)`에서 `userProfile`의 `dailyRecommendedIntake`와 `consumedDiets` 데이터를 확인합니다.
                            2.  **하루 총 섭취량 계산:** 모든 식사의 영양성분을 합산하여 하루 총 섭취량을 계산합니다.
                            3.  **총평 데이터 준비:** 계산된 총 섭취량과 `dailyRecommendedIntake`를 비교하여, 종합 점수, 칭찬할 점, 개선할 점(부족/과다 수치 포함)을 미리 구상합니다.
                            4.  **개별 식단 데이터 확인:** 아침, 점심, 저녁, 간식, '해당없음' 데이터가 각각 있는지 파악합니다.

                        ### [2단계: 마크다운 리포트 생성]
                        *   **아래 '출력 가이드라인'에 따라, 반드시 다음 순서로 리포트를 작성합니다.**
                            1.  **가장 먼저, '가. 하루 식단 총평' 섹션을 생성합니다.**
                            2.  **그 다음에, '나. 개별 식단 분석' 섹션들을 (아침, 점심, 저녁, 간식, 그 외) 순서대로 생성합니다.**

                        ### [3단계: 최종 검토] (이 내용은 절대 출력하지 마세요)
                        *   생성된 리포트에 '총평' 섹션과 모든 '개별 식단 분석' 섹션이 올바른 순서로 포함되었는지 최종 점검합니다.

                        ---

                        ## 4. 최종 출력 규칙 (Final Output Rule)
                        **매우 중요: 사용자인 나에게는 오직 [2단계]에서 생성된 최종 마크다운 리포트 텍스트만을 보여주세요. 당신의 내부 분석 과정이나 최종 검토 내용은 절대로 출력물에 포함시키지 마세요.**

                        ---

                        ## 5. 출력 가이드라인 (Markdown Generation Rules)

                        ### 가. 하루 식단 총평 (가장 먼저 표시)
                        **이 섹션은 리포트의 가장 처음에 항상 표시되어야 합니다.**
                        *   `# 🍽️ 하루 식단 총평` 제목
                        *   **종합 점수:** 100점 만점의 점수를 굵게 표시합니다.
                            *   *점수 기준:* 하루 권장 섭취량 대비 총 섭취량의 칼로리, 탄/단/지 균형, 나트륨/당류 제한 등을 종합적으로 평가합니다.
                        *   `## 📈 잘하고 있어요!` 섹션
                            *   하루 전체 식단에서 칭찬할 만한 점 1~2가지를 구체적으로 작성합니다. (예: "하루 식이섬유 섭취량이 권장량을 충족했어요!", "다양한 식품군을 통해 영양소를 골고루 섭취하셨네요.")
                        *   `## 💡 개선하면 좋아요!` 섹션
                            *   하루 전체에서 가장 개선이 필요한 점 1~3가지를 **구체적인 수치와 실천 방안**과 함께 제안합니다. (예: "하루 단백질 섭취가 권장량보다 약 30g 부족해요. 내일 점심에 계란 2개를 추가해보세요.")

                        ---

                        ### 나. 개별 식단 분석 (총평 다음에 표시)
                        **아침, 점심, 저녁, 간식, 그 외 순서로 각 섹션을 생성합니다.**

                        ### 1. 아침, 점심, 저녁 분석
                        *   **데이터가 있는 경우:**
                            *   **식사별 제목:** 이모지와 함께 제목을 작성합니다. (예: `## ☀️ 아침 식단 분석`)
                            *   **점수:** 100점 만점의 점수를 굵게 표시합니다. (예: **점수: 85점** / 100점)
                            *   **잘한 점:** `👍 **잘한 점**` 제목과 함께 긍정적인 측면 1~2가지를 칭찬합니다.
                            *   **개선할 점:** `💡 **개선할 점**` 제목과 함께 구체적인 개선점 1~2가지를 제안합니다.
                        *   **데이터가 없는 경우:**
                            *   **가이드 제목:** (예: `## 🥗 점심 식사 가이드`)
                            *   **추천 및 팁:** "점심 식사 기록이 없네요!"와 같은 문구와 함께, 건강 식단 아이디어 및 팁을 제공합니다.

                        ### 2. 간식 분석
                        *   **데이터가 있는 경우:**
                            *   `## 🍎 간식 분석` 섹션을 만들고, 섭취한 간식에 대한 **코멘트**와 **개선 제안**을 작성합니다. (점수는 필수는 아님)
                        *   **데이터가 없는 경우:**
                            *   `## 🍎 건강한 간식 가이드` 섹션을 만들고, 일반적인 건강 간식을 추천합니다. (예: "출출할 때를 대비해 건강한 간식을 추천해 드릴게요! **견과류 한 줌(약 20g)**이나 **플레인 요거트**는 좋은 선택이 될 수 있어요.")

                        ### 3. '그 외' 식사 분석
                        *   **`mealType`이 '해당없음'인 식단 데이터가 있을 경우에만 이 섹션을 생성합니다.**
                        *   **섹션 제목:** `## 🧐 그 외 식사 분석`
                        *   **내용:** 목록 형태로 각 항목을 나열하고, 점수 없이 간단한 코멘트를 추가합니다.
                            *   *예시 1 (영양제):*
                                *   **비타민C 영양제:** 활력 증진에 도움이 되는 좋은 습관입니다! 식사 직후에 드시면 흡수율을 높일 수 있어요.
                            *   *예시 2 (커피):*
                                *   **아메리카노:** 집중력 향상에 도움이 될 수 있지만, 하루 총 카페인 섭취량을 고려해주세요. 설탕이나 시럽 추가는 피하는 것이 좋습니다.

                        ---
                        ```json
                        \(encodedData)
                        ```
                                                        
                        """
                        
                        let text = try await firebaseAIService.generate(prompt)
                        await send(.aiResponse(.success(text)))
                        await send(.getEncodeData(encodedData))
                }
            }
        case .aiResponse(.success(let text)):
            state.isLoading = false
            state.generatedResponse = text
            print("success - \(text)")
            return .none
        case .aiResponse(.failure(let error)):
            state.isLoading = false
            state.generatedResponse = "AI 분석 중 오류가 발생했습니다.: \(error.localizedDescription)"
            print("AI Error: \(error.localizedDescription)")
            return .none
            
        case .getEncodeData(let encodedData):
            state.encodedData = encodedData
            return .none
            
        case .aiAnalyzeSave(let cleanedResponse):
            return .run { [encodedData = state.encodedData] send in
                await MainActor.run {
                    do {
                        let context = modelContainer.mainContext
                        
                        let analyzeHistory = AnalyzeHistory(
                            encodedData: encodedData,
                            cleanedResponse: cleanedResponse
                        )
                        
                        context.insert(analyzeHistory)
                        
                        try context.save()
                        
                        print("AI 분석 결과가 성공적으로 저장되었습니다.")
                        
                    } catch {
                        print("AI 분석 결과 저장 실패: \(error.localizedDescription)")
                    }
                }
                await send(.delegate(.saveAnalyze))
            }
        case .delegate(_):
            return .none
        }
    }
}

struct FirebaseAIService {
    var generate: (_ prompt: String) async throws -> String
}

extension FirebaseAIService: DependencyKey {
    static var liveValue: Self = {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        
        let model = ai.generativeModel(modelName: "gemini-2.0-flash-lite")
        
        return Self(
            generate: { prompt in
                let response = try await model.generateContent(prompt)
                return response.text ?? "NO text in response"
            }
        )
    }()
}

extension DependencyValues {
    var firebaseAIService: FirebaseAIService {
        get { self[FirebaseAIService.self] }
        set { self[FirebaseAIService.self] = newValue }
    }
}

