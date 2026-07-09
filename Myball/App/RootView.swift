// RootView.swift
// 앱의 최상위 뷰 — 팀 선택 여부에 따라 화면 분기
// Flutter의 MaterialApp에서 home을 조건에 따라 바꾸는 것과 비슷

import SwiftUI

struct RootView: View {
    // @AppStorage: UserDefaults 값을 실시간으로 감시
    // 값이 바뀌면 자동으로 화면이 다시 그려짐 (Flutter의 StreamBuilder와 비슷)
    @AppStorage(Constants.selectedTeamIDKey, store: UserDefaults(suiteName: Constants.appGroupID))
    private var selectedTeamID: String?

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
        }
        #endif
    }

    // MARK: - 메인 탭 화면
    private func mainTabView(team: Team) -> some View {
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
