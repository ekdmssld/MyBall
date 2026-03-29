# MyBall - iOS 야구 일정 캘린더 앱

## 프로젝트 개요
MyBall은 사용자가 응원하는 야구팀을 설정하면, 해당 팀의 시즌 경기 일정을 자동으로 불러와 캘린더 형태로 보여주는 iOS 앱입니다.

## 핵심 기능
- 마이팀 설정 (KBO 10개 팀 / MLB 30개 팀)
- 경기 일정 캘린더 뷰 (월별)
- 경기 상세 정보 (시간, 장소, 상대팀)
- iOS 캘린더 연동 (EventKit)
- 홈화면 위젯 (WidgetKit - Small/Medium/Large)
- 커스텀 배경화면 생성 및 저장
- 경기 시작 전 푸시 알림

## 기술 스택
- 언어: Swift 5.9+
- UI: SwiftUI
- 최소 타겟: iOS 17.0
- 아키텍처: MVVM + Clean Architecture
- 비동기: Swift Concurrency (async/await)
- 로컬 저장: SwiftData + UserDefaults (App Group 공유)
- 네트워크: URLSession
- 이미지 캐시: Kingfisher
- 위젯: WidgetKit
- 캘린더: EventKit
- 알림: UserNotifications

## 프로젝트 구조
```
MyBall/
├── App/                    # 앱 진입점
│   ├── MyBallApp.swift     # @main, SwiftData 컨테이너
│   └── RootView.swift      # 팀 선택 여부에 따른 분기 + TabView
├── Core/                   # 공통 유틸리티
│   ├── Constants.swift     # App Group ID, API URL, 키 상수
│   ├── Theme.swift         # 색상, 폰트, 간격 디자인 토큰
│   └── Extensions/
│       └── Date+Extensions.swift  # ESPN 날짜 포맷, 한국어 날짜
├── Domain/                 # 비즈니스 로직 (순수 Swift, UI 의존 없음)
│   ├── Models/
│   │   ├── League.swift    # KBO/MLB enum
│   │   ├── Team.swift      # 팀 모델 + KBO 10개 팀 데이터 + Color 헬퍼
│   │   └── Game.swift      # 경기 모델, GameTeam, GameStatus
│   ├── Protocols/
│   │   └── Repositories.swift  # ScheduleRepositoryProtocol, TeamRepositoryProtocol
│   └── UseCases/
│       └── FetchScheduleUseCase.swift  # 월별 내 팀 경기 필터링
├── Data/                   # 외부 데이터 소스
│   ├── Network/
│   │   ├── APIClient.swift     # URLSession ESPN API 호출 (싱글톤)
│   │   └── DTOs/
│   │       └── ESPNDTOs.swift  # ESPN JSON → Domain 모델 매핑
│   ├── Repository/
│   │   ├── ScheduleRepository.swift  # 캐시 + API 호출 조합
│   │   └── TeamRepository.swift      # UserDefaults (App Group) 저장
│   └── Cache/
│       └── ScheduleCache.swift       # 인메모리 + SwiftData 캐시
├── Features/               # 화면별 모듈 (각각 View + ViewModel)
│   ├── TeamSelection/      # 팀 선택 화면 (그리드)
│   ├── Calendar/           # 캘린더 메인 화면 (월별 그리드)
│   ├── GameDetail/         # 경기 상세 + 캘린더 추가 + 배경화면 이동
│   ├── Settings/           # 설정 (팀 변경, 알림, 캐시)
│   ├── Wallpaper/          # 배경화면 생성 (3가지 스타일) + 사진 저장
│   └── Debug/              # API 디버그 화면 (#if DEBUG)
├── Widget/                 # WidgetKit Extension (별도 타겟)
│   └── MyBallWidget.swift  # TimelineProvider + Small/Medium/Large
└── Resources/
    └── Assets.xcassets
```

## API
ESPN 비공식 API (인증 불필요):
- 스코어보드: `https://site.api.espn.com/apis/site/v2/sports/baseball/{kbo|mlb}/scoreboard?dates=YYYYMMDD`
- 팀 목록: `https://site.api.espn.com/apis/site/v2/sports/baseball/{kbo|mlb}/teams`
- 비공식 API이므로 언제든 변경/중단될 수 있음 → 에러 핸들링과 캐시 필수

## App Group
- ID: `group.com.myball.shared`
- 메인 앱과 Widget Extension이 UserDefaults와 SwiftData를 공유

## 빌드 & 실행
```bash
# Xcode에서 프로젝트 열기
open MyBall.xcodeproj

# 또는 터미널에서 빌드
xcodebuild -scheme MyBall -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 코드 컨벤션
- SwiftUI View는 body를 짧게 유지하고 private 서브뷰로 분리
- ViewModel은 @MainActor + ObservableObject
- 모든 API 호출은 async/await 사용
- 에러는 do-try-catch로 처리하고 사용자에게 피드백
- 한국어 주석을 적극 사용 (학습 목적)
- #if DEBUG로 디버그 전용 코드 분리

## 개발자 참고사항
- 이 프로젝트의 개발자는 Swift/SwiftUI 초보입니다
- Flutter 경험이 약간 있습니다
- 코드 설명 시 Flutter와 비교하면 이해가 빠릅니다
- 한 번에 많은 변경보다 작은 단위로 나누어 진행해주세요
- 새로운 Swift 문법을 사용할 때는 간단한 설명을 주석으로 달아주세요
