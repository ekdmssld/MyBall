// APIDebugView.swift
// API와 기능을 직접 테스트해볼 수 있는 디버그 화면
// #if DEBUG로 감싸서 릴리즈 빌드에서는 제외됨

#if DEBUG
import SwiftUI
import UserNotifications

struct APIDebugView: View {
    // @State: 이 화면의 로컬 상태 (Flutter의 setState와 비슷)
    @State private var responseText: String = "테스트할 기능을 선택하세요"
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.large) {
                // KBO API 테스트
                HStack(spacing: Theme.Spacing.medium) {
                    Button("이번 달 일정 조회") {
                        Task { await fetchSchedule() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("순위표 조회") {
                        Task { await fetchStandings() }
                    }
                    .buttonStyle(.bordered)
                }

                // 알림 딥링크 테스트 (5초 후 알림 → 탭하면 라이브 화면)
                Button("알림 테스트 (5초 후 발송)") {
                    Task {
                        await sendTestNotification()
                        responseText = "5초 후 알림이 옵니다.\n홈 화면으로 나가서 알림을 탭하면\n라이브 경기 센터가 열립니다."
                    }
                }
                .buttonStyle(.bordered)

                // Live Activity 테스트 (더미 데이터로 잠금화면 UI 확인)
                HStack(spacing: Theme.Spacing.medium) {
                    Button("라이브 액티비티 시작") {
                        Task {
                            await LiveActivityService.shared.startDummy()
                            responseText = "더미 Live Activity를 시작했습니다.\n홈 화면으로 나가거나 폰을 잠그면\n잠금화면/Dynamic Island에서 확인할 수 있습니다."
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Button("종료") {
                        Task {
                            await LiveActivityService.shared.endDummy()
                            responseText = "더미 Live Activity를 종료했습니다."
                        }
                    }
                    .buttonStyle(.bordered)
                }

                // 결과 표시
                if isLoading {
                    ProgressView("로딩 중...")
                } else {
                    ScrollView {
                        Text(responseText)
                            .font(.system(size: 11, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer()
            }
            .padding(.top, Theme.Spacing.large)
            .navigationTitle("디버그")
        }
    }

    // 이번 달 KBO 일정 테스트
    private func fetchSchedule() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let calendar = Calendar.current
            let now = Date()
            let games = try await KBOAPIClient.shared.fetchMonthSchedule(
                year: calendar.component(.year, from: now),
                month: calendar.component(.month, from: now)
            )
            let summary = games.prefix(30).map { game in
                "\(game.date.koreanDateString) \(game.awayTeam.name) @ \(game.homeTeam.name) — \(game.status.displayText) \(game.scoreText ?? "")"
            }.joined(separator: "\n")

            responseText = "=== 이번 달 KBO 일정 (\(games.count)경기) ===\n\(summary)"
        } catch {
            responseText = "에러: \(error.localizedDescription)"
        }
    }

    // KBO 순위표 테스트
    private func fetchStandings() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let standings = try await KBOAPIClient.shared.fetchStandings()
            let summary = standings.map { s in
                "\(s.rank)위 \(s.teamName) — \(s.recordText) 승률 \(s.winRate) 게임차 \(s.gamesBehind)"
            }.joined(separator: "\n")

            responseText = "=== KBO 순위 ===\n\(summary)"
        } catch {
            responseText = "에러: \(error.localizedDescription)"
        }
    }

    // 알림 딥링크 테스트용 — 5초 후 가짜 경기 알림 발송
    private func sendTestNotification() async {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else {
            responseText = "알림 권한이 없습니다"
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "경기 시작 30분 전"
        content.body = "vs LG — 홈 경기가 곧 시작됩니다! (테스트)"
        content.sound = .default
        content.categoryIdentifier = Constants.notificationCategoryGameStart  // 이 카테고리가 딥링크 트리거
        content.userInfo = [
            Constants.notificationDestinationKey: Constants.notificationDestinationLiveCenter
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "debug-test", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}

#Preview {
    APIDebugView()
}
#endif
