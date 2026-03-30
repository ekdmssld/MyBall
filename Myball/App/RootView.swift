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
            if selectedTeamID != nil {
                // 팀이 선택되어 있으면 → 메인 탭 화면 (Phase 4에서 구현)
                mainTabView
            } else {
                // 팀이 선택되어 있지 않으면 → 팀 선택 화면 (Phase 4에서 구현)
                placeholderView
            }
        }
    }

    // 임시 메인 화면 (Phase 4에서 CalendarMainView로 교체)
    private var mainTabView: some View {
        TabView {
            // 캘린더 탭
            VStack {
                if let team = Team.find(by: selectedTeamID ?? "") {
                    Text("\(team.name)")
                        .font(Theme.Fonts.title)
                    Text("캘린더 화면은 Phase 4에서 구현됩니다")
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .tabItem {
                Label("캘린더", systemImage: "calendar")
            }

            // 설정 탭
            VStack {
                Text("설정 화면은 Phase 5에서 구현됩니다")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
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

    // 임시 팀 선택 화면 (Phase 4에서 TeamSelectionView로 교체)
    private var placeholderView: some View {
        VStack(spacing: Theme.Spacing.extraLarge) {
            Image(systemName: "baseball")
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.primary)

            Text("MyBall")
                .font(.largeTitle.bold())

            Text("응원하는 팀을 선택하세요")
                .foregroundStyle(Theme.Colors.secondaryLabel)

            // 임시: 빠르게 테스트하기 위한 팀 선택 버튼들
            VStack(spacing: Theme.Spacing.medium) {
                Text("MLB 인기 팀 (테스트)")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)

                let sampleTeams = Array(Team.mlbTeams.prefix(6))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(sampleTeams) { team in
                        Button {
                            // 팀 선택 → UserDefaults에 저장 → @AppStorage가 감지 → 화면 전환
                            let repo = TeamRepository()
                            repo.saveSelectedTeam(team)
                        } label: {
                            Text(team.shortName)
                                .font(Theme.Fonts.teamName)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(team.color.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.extraLarge)
        }
    }
}

#Preview("팀 미선택") {
    RootView()
}
