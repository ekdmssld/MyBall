# ⚾ MyBall iOS 앱 개발 절차

> **총 예상 기간:** 6~8주 (Swift 학습 포함)
> **기술 스택:** Swift + SwiftUI + WidgetKit + ESPN API
> **도구:** Xcode + Claude Code (터미널)

---

## Phase 0: 환경 세팅 `Day 1`

- [ ] **Xcode 설치**
    - Mac App Store에서 Xcode 검색 후 설치 (약 12GB)
    - 설치 후 처음 실행 시 추가 컴포넌트 모두 설치
- [ ] **Apple Developer 계정 가입**
    - [developer.apple.com](https://developer.apple.com) 에서 가입
    - 무료 계정으로 시뮬레이터 개발 가능
    - 실기기 테스트 및 App Store 배포 시 유료 ($99/년) 필요
- [ ] **Claude Code 설치**
    ```bash
    curl -fsSL https://claude.ai/install.sh | bash
    ```
    - 설치 후 터미널 새로 열고 `claude --version`으로 확인
- [ ] **Claude Code 로그인**
    ```bash
    claude
    ```
    - 브라우저가 열리면 Pro/Max 계정으로 인증
- [ ] **Git 초기화**
    ```bash
    git init && git add . && git commit -m "init: 프로젝트 초기 세팅"
    ```

---

## Phase 1: 프로젝트 생성 `Day 1-2`

- [ ] **Xcode 새 프로젝트 생성**
    - File → New → Project → iOS → App
    - Product Name: `MyBall`
    - Interface: `SwiftUI`
    - Language: `Swift`
    - Storage: `SwiftData`
    - Include Tests ✅
- [ ] **Widget Extension 타겟 추가**
    - File → New → Target → Widget Extension
    - Product Name: `MyBallWidget`
    - Include Configuration App Intent ✅
- [ ] **App Group 설정**
    - Signing & Capabilities → + Capability → App Groups
    - `group.com.myball.shared` 생성
    - ⚠️ 메인 앱 타겟 + Widget 타겟 양쪽 모두에 동일하게 설정
- [ ] **Kingfisher 패키지 추가**
    - File → Add Package Dependencies
    - URL: `https://github.com/onevcat/Kingfisher`
- [ ] **Info.plist 권한 설정**
    - `NSCalendarsFullAccessUsageDescription` — 경기 일정을 iOS 캘린더에 추가하기 위해 캘린더 접근 권한이 필요합니다.
    - `NSPhotoLibraryAddUsageDescription` — 배경화면을 사진첩에 저장하기 위해 사진 접근 권한이 필요합니다.
- [ ] **CLAUDE.md, SKILLS.md 배치**
    - 프로젝트 루트 폴더(.xcodeproj와 같은 위치)에 복사
- [ ] **폴더 구조 생성**
    ```
    MyBall/
    ├── App/
    ├── Core/Extensions/
    ├── Domain/Models/
    ├── Domain/Protocols/
    ├── Domain/UseCases/
    ├── Data/Network/DTOs/
    ├── Data/Repository/
    ├── Data/Cache/
    ├── Features/TeamSelection/
    ├── Features/Calendar/
    ├── Features/GameDetail/
    ├── Features/Settings/
    ├── Features/Wallpaper/
    ├── Features/Debug/
    ├── Widget/
    └── Resources/
    ```

---

## Phase 2: Swift 기초 학습 `Day 2-4`

> 💡 Xcode → File → New → Playground에서 실습

- [ ] **변수, 상수, 타입 연습**
    - `let` (상수) / `var` (변수)
    - `String`, `Int`, `Double`, `Bool`
    - 옵셔널 `?` 과 `if let` 언래핑
- [ ] **배열, 딕셔너리, 반복문 연습**
    - `Array` — append, count, subscript
    - `Dictionary` — 키-값 저장
    - `for-in`, `map`, `filter`, `compactMap`
- [ ] **struct와 enum 만들어보기**
    - `Team` struct (id, name, shortName, color)
    - `GameStatus` enum (scheduled, inProgress, final)
    - 계산 프로퍼티(computed property) 작성
- [ ] **SwiftUI 기본 View 만들기**
    - `VStack` = Flutter Column
    - `HStack` = Flutter Row
    - `Text`, `Button`, `Image`
    - `.padding()`, `.font()`, `.foregroundColor()`
- [ ] **@State로 상태 관리 실습**
    - @State 변수 선언 → 버튼으로 값 변경 → 화면 자동 갱신 확인
    - $바인딩 문법 이해 (Toggle, TextField 등)
- [ ] **List와 NavigationStack 실습**
    - `List` = Flutter ListView
    - `NavigationLink` = Flutter Navigator.push
    - 목록 화면 → 상세 화면 이동 흐름

---

## Phase 3: 핵심 모델 & API 연동 `Week 2`

### 데이터 모델

- [ ] **League.swift 작성**
    - KBO / MLB enum, displayName, espnPath
- [ ] **Team.swift 작성**
    - 팀 모델 + KBO 10개 팀 하드코딩 데이터
    - HEX 색상 → SwiftUI Color 변환
- [ ] **Game.swift 작성**
    - 경기 모델 (id, date, homeTeam, awayTeam, venue, status)
    - GameTeam, GameStatus 정의
    - `isHome()`, `opponent()` 헬퍼 메서드

### API 연동

- [ ] **ESPN API 엔드포인트 확인**
    - 디버그 화면(APIDebugView)에서 KBO/MLB 스코어보드 테스트
    - 팀 목록 API로 실제 ESPN 팀 ID 확인
- [ ] **ESPNDTOs.swift 작성**
    - ESPN JSON 구조에 맞는 Codable struct
    - `toDomain()` 메서드로 Domain 모델 변환
- [ ] **APIClient.swift 구현**
    - URLSession 싱글톤
    - `fetchScoreboard(league:date:)` async throws
    - `fetchTeams(league:)` async throws
    - 에러 타입 정의 (APIError enum)
- [ ] **Team.swift에 실제 ESPN 팀 ID 반영**
    - 디버그 화면에서 확인한 ID와 로고 URL로 업데이트

### 저장소

- [ ] **ScheduleRepository 구현**
    - 캐시 확인 → 없으면 API 호출 → 캐시 저장
- [ ] **TeamRepository 구현**
    - UserDefaults(suiteName: App Group)로 선택 팀 저장/불러오기
- [ ] **ScheduleCache 구현**
    - 인메모리 캐시 (NSLock + Dictionary)
    - 만료 시간 설정 (30분)

---

## Phase 4: 메인 화면 UI `Week 2-3`

### 팀 선택

- [ ] **TeamSelectionView 구현**
    - KBO / MLB 세그먼트 탭
    - LazyVGrid 2열 팀 카드 그리드
    - 팀 로고(색상 원) + 팀명
    - 선택 시 하이라이트 애니메이션
    - '선택 완료' 버튼 → UserDefaults 저장
- [ ] **TeamSelectionViewModel 구현**
    - @Published selectedLeague, selectedTeam, teams
    - 리그 변경 시 팀 목록 갱신

### 메인 화면

- [ ] **RootView 분기 로직**
    - @AppStorage로 selectedTeamId 확인
    - 비어있으면 → TeamSelectionView
    - 있으면 → MainTabView (캘린더 + 설정)
- [ ] **CalendarMainView 구현**
    - 월 네비게이션 (이전/다음 월 버튼)
    - 요일 헤더 (일~토, 주말 색상 구분)
    - LazyVGrid 7열 날짜 셀
    - 경기 있는 날: 상대팀 약칭 + 시간 + 홈/원정 배경색
    - 오늘 날짜 파란색 원 표시
- [ ] **CalendarViewModel 구현**
    - 현재 월 기준 날짜 배열 생성 (앞쪽 빈칸 포함)
    - API에서 월별 경기 로드 → 내 팀 경기만 필터링
    - `game(for: Date)` 메서드로 날짜별 경기 매핑
- [ ] **다음 경기 요약 카드**
    - 캘린더 상단에 NextGameCardView
    - 상대팀, 날짜, 시간, 홈/원정 배지 표시
- [ ] **경기 상세 화면 (GameDetailView)**
    - 날짜 셀 탭 → `.sheet(item:)` 로 하프 시트 표시
    - 원정 vs 홈 팀 대결 헤더
    - 날짜, 시간, 장소 정보
    - 스코어 (경기 종료 시)
    - '캘린더에 추가' 버튼
    - '배경화면 만들기' 버튼

---

## Phase 5: iOS 기능 연동 `Week 3-4`

### 캘린더 연동

- [ ] **EventKit 연동**
    - `EKEventStore.requestFullAccessToEvents()` 권한 요청
    - `EKEvent` 생성 (제목, 시간, 장소, 알림)
    - 기본 캘린더 또는 '야구 일정' 전용 캘린더에 저장
    - 중복 방지 로직 (동일 경기 ID 체크)

### 알림

- [ ] **로컬 푸시 알림 구현**
    - `UNUserNotificationCenter` 권한 요청
    - 경기 시작 1시간 전 / 30분 전 알림 예약
    - 알림 카테고리: gameStart, gameResult
    - 경기 결과 알림 (백그라운드 업데이트 시)

### 설정

- [ ] **SettingsView 구현**
    - 현재 응원팀 표시 + 변경 버튼
    - 알림 ON/OFF 토글
    - 알림 시간 선택 (30분 전 / 1시간 전 / 2시간 전)
    - 캐시 삭제 버튼
    - 앱 버전, 데이터 출처 표시

### 배경화면

- [ ] **WallpaperGeneratorView 구현**
    - 팀 컬러 기반 그라데이션 배경
    - 다음 경기 정보 오버레이 (상대팀, 날짜, 시간, 장소)
    - 3가지 스타일 선택 (기본, 다크, 비비드)
    - 미리보기 화면 (iPhone 모양 프레임)
- [ ] **사진첩 저장 기능**
    - `ImageRenderer` → `UIImage` (3x 해상도)
    - `UIImageWriteToSavedPhotosAlbum`으로 저장
    - 저장 완료 Alert

---

## Phase 6: 위젯 개발 `Week 4-5`

### 기반 작업

- [ ] **App Group 데이터 공유 확인**
    - 메인 앱에서 저장한 팀 정보를 Widget에서 읽을 수 있는지 테스트
    - `UserDefaults(suiteName: "group.com.myball.shared")`
- [ ] **TimelineProvider 구현**
    - `placeholder()` — 스켈레톤 데이터
    - `getSnapshot()` — 위젯 갤러리 미리보기용
    - `getTimeline()` — 실제 데이터 + 30분 후 리프레시

### 위젯 UI

- [ ] **Small 위젯**
    - 팀 이름 + 다음 경기 상대팀 + 날짜/시간 + 홈/원정 배지
- [ ] **Medium 위젯**
    - 왼쪽: 다음 경기 정보 / 오른쪽: 이번 주 경기 리스트 (최대 3개)
- [ ] **Large 위젯**
    - 팀 이름 + 주간 경기 리스트 (최대 5개) + 홈/원정 표시

### 테스트

- [ ] **위젯 미리보기 테스트**
    - Xcode Preview에서 모든 사이즈 확인
    - 시뮬레이터 홈화면에 위젯 추가하여 실제 동작 확인
    - 데이터 없는 상태 (시즌 오프) 대응 확인

---

## Phase 7: 다듬기 & 테스트 `Week 5-6`

### 에러 & 예외 처리

- [ ] **에러 상태 UI**
    - 네트워크 오류 → 재시도 버튼
    - 데이터 없음 → "예정된 경기가 없습니다" 표시
    - 로딩 중 → ProgressView + 스켈레톤 UI
- [ ] **오프라인 대응**
    - 캐시된 데이터 있으면 오프라인에서도 캘린더 표시
    - 네트워크 복구 시 자동 새로고침
- [ ] **ESPN API 변경 대응**
    - API 응답 필드는 모두 옵셔널 처리
    - API 장애 시 마지막 캐시 데이터 표시

### UX 개선

- [ ] **Pull-to-Refresh**
    - 캘린더 화면에서 아래로 당겨 새로고침
    - `.refreshable { await viewModel.loadGames() }`
- [ ] **애니메이션 추가**
    - 팀 선택 시 스프링 애니메이션
    - 화면 전환 시 부드러운 트랜지션
    - 위젯 데이터 로드 시 페이드 인
- [ ] **다크모드 대응**
    - 모든 화면에서 라이트/다크 모드 정상 표시 확인
    - Theme.swift 색상이 양쪽 모드에서 잘 보이는지 검증
- [ ] **접근성 검토**
    - VoiceOver 테스트 (화면 읽기)
    - Dynamic Type 지원 (글씨 크기 조절)

### 테스트

- [ ] **단위 테스트 작성**
    - Game 모델 — isHome(), opponent() 로직
    - FetchScheduleUseCase — 팀 필터링, 정렬
    - Date+Extensions — 날짜 포맷 변환
    - ScheduleCache — 캐시 저장/만료 로직
- [ ] **UI 테스트**
    - 팀 선택 → 캘린더 진입 플로우
    - 경기 탭 → 상세 시트 표시

---

## Phase 8: 출시 준비 `Week 7-8`

### 스토어 리소스

- [ ] **앱 아이콘 제작**
    - 1024 x 1024px 아이콘 디자인
    - Assets.xcassets → AppIcon에 추가
- [ ] **스크린샷 촬영**
    - iPhone 6.7인치 (15 Pro Max) — 필수
    - iPhone 6.1인치 (15 Pro) — 필수
    - 주요 화면: 팀 선택, 캘린더, 경기 상세, 위젯, 배경화면
- [ ] **앱 설명문 작성**
    - 한국어 / 영어 앱 이름, 부제, 설명
    - 키워드: 야구, KBO, MLB, 일정, 캘린더, 위젯
- [ ] **개인정보 처리방침 페이지**
    - 앱이 수집하는 데이터 명시 (App Store 필수 요구사항)
    - GitHub Pages 또는 Notion 공개 페이지로 작성 가능

### 배포

- [ ] **TestFlight 베타 배포**
    - App Store Connect에서 앱 등록
    - Xcode → Product → Archive → Distribute to App Store Connect
    - TestFlight에서 내부 테스터 초대
- [ ] **실기기 테스트**
    - 실제 iPhone에서 전체 플로우 확인
    - 위젯이 홈화면에서 정상 업데이트되는지
    - 알림이 제시간에 오는지
    - 배경화면 저장이 정상 동작하는지
    - 캘린더 이벤트가 정상 추가되는지
- [ ] **App Store 심사 제출**
    - App Store Connect에서 빌드 선택 → 심사 요청
    - 심사 기간: 보통 24~48시간
- [ ] **심사 리젝 대응**
    - 리젝 사유 확인 후 수정
    - Resolution Center에서 소명 또는 재제출
    - 평균 1~3회 리젝 발생 가능 (정상적임)

---

## 참고 사항

### ESPN API 주의점
- 비공식 API이므로 언제든 변경/중단 가능
- Rate limit 명시 없음 → 캐시 필수, 과도한 호출 자제
- KBO 경로(`/baseball/kbo`)가 동작하지 않을 수 있음 → 웹 파싱 대안 준비

### Claude Code 활용 팁
```bash
# 프로젝트 폴더에서 실행
cd ~/Developer/MyBall
claude

# 이런 식으로 요청
> CalendarMainView.swift 코드를 설명해줘
> 경기 상세 화면에 공유 버튼 추가해줘
> 이 에러 메시지가 뭔지 알려줘: [에러 붙여넣기]
> 위젯이 데이터를 못 불러오는 이유가 뭘까?
```

### 유용한 단축키 (Xcode)
| 단축키 | 기능 |
|--------|------|
| `Cmd + R` | 빌드 & 실행 |
| `Cmd + B` | 빌드만 |
| `Cmd + .` | 실행 중지 |
| `Cmd + Shift + O` | 파일 빠른 열기 |
| `Cmd + Shift + L` | 라이브러리 (UI 컴포넌트 검색) |
| `Ctrl + I` | 코드 들여쓰기 정리 |
| `Cmd + /` | 주석 토글 |
| `Cmd + Shift + K` | 빌드 캐시 정리 |
