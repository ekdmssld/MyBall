// RootView.swift
// 앱의 최상위 뷰 — 팀 선택 여부에 따라 화면 분기
// Flutter의 MaterialApp에서 home을 조건에 따라 바꾸는 것과 비슷

import SwiftUI
import UserNotifications

struct RootView: View {
    // @AppStorage: UserDefaults 값을 실시간으로 감시
    // 값이 바뀌면 자동으로 화면이 다시 그려짐 (Flutter의 StreamBuilder와 비슷)
    @AppStorage(Constants.selectedTeamIDKey, store: UserDefaults(suiteName: Constants.appGroupID))
    private var selectedTeamID: String?

    // 알림 탭 → 라이브 경기 센터 열기 신호를 감시
    @StateObject private var notificationDelegate = NotificationDelegate.shared

    var body: some View {
        Group {
            if let teamID = selectedTeamID, let team = Team.find(by: teamID) {
                // 팀이 선택되어 있으면 → 메인 탭 화면
                mainTabView(team: team)
            } else {
                // 팀이 선택되어 있지 않으면 → 팀 선택 화면
                TeamSelectionView()
            }
        }
        // 팀 변경 시 애니메이션
        .animation(.easeInOut(duration: 0.3), value: selectedTeamID)
        #if DEBUG
        // 실행 인자로 더미 Live Activity 시작 (자동화 테스트용)
        // 예: xcrun simctl launch <기기> TB.Myball -liveActivityDummy
        .task {
            if ProcessInfo.processInfo.arguments.contains("-liveActivityDummy") {
                await LiveActivityService.shared.startDummy()
            }
            // 딥링크 시트 배선 검증용: 알림 탭과 동일한 신호를 직접 발생
            if ProcessInfo.processInfo.arguments.contains("-openLiveCenter") {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                NotificationDelegate.shared.openLiveCenter = true
            }
            // 알림 딥링크 자동화 테스트용: 5초 후 테스트 알림 발송
            if ProcessInfo.processInfo.arguments.contains("-fireTestNotification") {
                _ = try? await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound])
                let content = UNMutableNotificationContent()
                content.title = "경기 시작 30분 전"
                content.body = "vs LG — 홈 경기가 곧 시작됩니다! (테스트)"
                content.categoryIdentifier = "gameStart"
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: "uitest-noti", content: content, trigger: trigger)
                try? await UNUserNotificationCenter.current().add(request)
            }
        }
        #endif
    }

    // MARK: - 메인 탭 화면
    private func mainTabView(team: Team) -> some View {
        tabView(team: team)
            // 경기 알림을 탭하면 라이브 경기 센터를 시트로 표시
            .sheet(isPresented: $notificationDelegate.openLiveCenter) {
                NavigationStack {
                    LiveGameView(team: team)
                }
            }
    }

    private func tabView(team: Team) -> some View {
        TabView {
            // 홈 탭 — 다음 경기, 성적, 최근 결과 요약
            HomeView(team: team)
                .tabItem {
                    Label("홈", systemImage: "house")
                }

            // 캘린더 탭
            CalendarMainView(team: team)
                .tabItem {
                    Label("캘린더", systemImage: "calendar")
                }

            // 설정 탭
            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }

            // 디버그 탭 (개발 중에만 표시)
            #if DEBUG
            APIDebugView()
                .tabItem {
                    Label("디버그", systemImage: "ant")
                }
            #endif
        }
    }
}

#Preview("팀 미선택") {
    RootView()
}
