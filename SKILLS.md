# MyBall 프로젝트 스킬

## 스킬 1: SwiftUI View 생성

새로운 화면을 만들 때 다음 패턴을 따릅니다:

```swift
import SwiftUI

struct {Name}View: View {
    @StateObject private var viewModel = {Name}ViewModel()

    var body: some View {
        // 메인 콘텐츠
    }
}

// MARK: - 서브뷰는 private extension 또는 별도 struct로 분리

#Preview {
    {Name}View()
}
```

규칙:
- View 파일과 ViewModel 파일은 같은 폴더에 위치
- body는 최대한 짧게, 복잡한 UI는 private 서브뷰로 분리
- Preview를 항상 포함하여 Xcode Canvas에서 즉시 확인 가능하게
- 하드코딩된 문자열은 최소화하고 Theme.swift 참조

## 스킬 2: ViewModel 생성

```swift
import SwiftUI

@MainActor
final class {Name}ViewModel: ObservableObject {
    // 상태 (화면에 표시될 데이터)
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // 의존성
    private let useCase: SomeUseCase

    init(useCase: SomeUseCase = SomeUseCase(repository: SomeRepository())) {
        self.useCase = useCase
    }

    // 액션 (View에서 호출)
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await useCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

규칙:
- @MainActor 필수 (UI 업데이트 스레드 안전성)
- @Published 변수는 View가 관찰하는 상태
- 의존성 주입은 init 파라미터에 기본값으로 제공
- 비동기 작업은 async/await + do-try-catch
- isLoading과 errorMessage는 표준 패턴으로 항상 포함

## 스킬 3: API 엔드포인트 추가

ESPN API 새 엔드포인트 추가 시:

1. DTOs/ESPNDTOs.swift에 Codable struct 추가
2. APIClient.swift에 호출 메서드 추가
3. Domain 모델로 매핑하는 toDomain() 작성
4. Repository에서 캐시 로직과 함께 호출

```swift
// 1) DTO (ESPNDTOs.swift에 추가)
struct ESPNNewResponse: Decodable {
    let data: [ESPNNewItem]
}

// 2) APIClient 메서드
func fetchNewData(league: League) async throws -> [NewModel] {
    let urlString = "\(AppConstants.espnBaseURL)/\(league.espnPath)/newEndpoint"
    guard let url = URL(string: urlString) else { throw APIError.invalidURL }
    let (data, _) = try await session.data(from: url)
    let response = try decoder.decode(ESPNNewResponse.self, from: data)
    return response.data.compactMap { $0.toDomain() }
}
```

규칙:
- ESPN API는 비공식이므로 응답 필드는 옵셔널(?)로 안전하게 처리
- 모든 호출에 디버그 로그 포함 (#if DEBUG)
- Rate limit 대비 캐시 필수 (ScheduleCache 사용)

## 스킬 4: Widget 업데이트

위젯 관련 수정 시:

```swift
// Widget/MyBallWidget.swift
// TimelineProvider 수정 → 데이터 표시 변경
// Small/Medium/Large 각각의 레이아웃 독립적으로 수정
```

규칙:
- Widget은 별도 타겟이므로 공유 데이터는 App Group 통해서만 접근
- UserDefaults(suiteName: AppConstants.appGroupId) 사용
- 위젯은 최소 15분 간격으로만 업데이트 가능 (시스템 제한)
- 위젯에서 네트워크 호출 시 타임아웃을 짧게 설정 (10초)
- containerBackground 수정자 필수 (iOS 17+)

## 스킬 5: 새로운 Feature 모듈 추가

```
Features/
└── NewFeature/
    ├── NewFeatureView.swift       # SwiftUI View
    └── NewFeatureViewModel.swift  # ObservableObject ViewModel
```

1. Features/ 하위에 폴더 생성
2. View + ViewModel 쌍으로 생성
3. 필요하면 Domain/Models에 모델 추가
4. 네비게이션은 부모 View의 NavigationLink 또는 .sheet으로 연결
5. RootView.swift 또는 MainTabView에서 접근 경로 추가

## 스킬 6: 코드 설명 스타일

이 프로젝트의 개발자는 Swift 초보이므로:

- 새로운 문법 사용 시 반드시 한줄 주석으로 설명
- Flutter 대응 개념이 있으면 비교 언급
- 한 번에 100줄 이상 변경하지 않기
- 변경 전후를 명확히 설명
- "왜" 이렇게 하는지 이유를 같이 설명

```swift
// ✅ 좋은 예
@State private var count = 0  // 값이 바뀌면 화면 자동 갱신 (Flutter의 setState와 유사)

// ❌ 나쁜 예 (설명 없음)
@State private var count = 0
```

## 스킬 7: 에러 처리 패턴

```swift
// View에서
.overlay {
    if viewModel.isLoading {
        ProgressView("불러오는 중...")
    }
}
.alert("오류", isPresented: $viewModel.showError) {
    Button("다시 시도") { Task { await viewModel.retry() } }
    Button("확인", role: .cancel) { }
} message: {
    Text(viewModel.errorMessage ?? "알 수 없는 오류")
}

// ViewModel에서
func loadData() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
        data = try await useCase.execute()
    } catch let error as APIError {
        errorMessage = error.errorDescription
        showError = true
    } catch {
        errorMessage = "네트워크 연결을 확인해주세요."
        showError = true
    }
}
```

## 스킬 8: Git 커밋 메시지 규칙

```
feat: 새로운 기능 추가
fix: 버그 수정
refactor: 코드 리팩토링 (기능 변경 없음)
style: UI/디자인 변경
docs: 문서 수정
chore: 빌드/설정 변경
```

예시:
- `feat: 캘린더 화면에 다음 경기 카드 추가`
- `fix: KBO 팀 ID ESPN 매핑 오류 수정`
- `refactor: APIClient 에러 처리 개선`

## 스킬 9: 테스트

```swift
import Testing

@Test func testGameFiltering() {
    let games = [/* mock data */]
    let filtered = games.filter { $0.homeTeam.id == "7" || $0.awayTeam.id == "7" }
    #expect(filtered.count == 2)
}
```

규칙:
- Swift Testing 프레임워크 사용 (iOS 17+)
- Domain 레이어(Models, UseCases) 우선 테스트
- Mock 데이터는 테스트 파일 내에 정의
