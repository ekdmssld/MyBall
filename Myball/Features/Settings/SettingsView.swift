// SettingsView.swift
// 설정 화면 — 팀 변경, 알림, 캐시 관리

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                // 응원팀 섹션
                teamSection

                // 알림 섹션
                notificationSection

                // 데이터 섹션
                dataSection

                // 정보 섹션
                infoSection
            }
            .navigationTitle("설정")
            .task {
                await viewModel.loadPendingCount()
            }
        }
    }

    // MARK: - 응원팀
    private var teamSection: some View {
        Section {
            if let team = viewModel.selectedTeam {
                HStack(spacing: Theme.Spacing.medium) {
                    // 팀 색상 원
                    Circle()
                        .fill(team.color)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(team.abbreviation.prefix(2))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(team.name)
                            .font(Theme.Fonts.headline)
                        Text(team.league.displayName)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }

                    Spacer()
                }
            }

            Button("응원팀 변경", role: .destructive) {
                viewModel.changeTeam()
            }
        } header: {
            Text("응원팀")
        }
    }

    // MARK: - 알림
    private var notificationSection: some View {
        Section {
            // 알림 ON/OFF
            Toggle("경기 알림", isOn: $viewModel.notificationEnabled)
                .onChange(of: viewModel.notificationEnabled) {
                    Task { await viewModel.toggleNotification() }
                }

            // 알림 시간 선택 (알림 켜져있을 때만)
            if viewModel.notificationEnabled {
                Picker("알림 시간", selection: $viewModel.notificationLeadTime) {
                    ForEach(viewModel.leadTimeOptions, id: \.self) { minutes in
                        Text(viewModel.leadTimeText(minutes)).tag(minutes)
                    }
                }

                // 예약된 알림 수
                HStack {
                    Text("예약된 알림")
                    Spacer()
                    Text("\(viewModel.pendingNotificationCount)개")
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        } header: {
            Text("알림")
        } footer: {
            Text("경기 시작 전에 푸시 알림을 받을 수 있습니다.")
        }
    }

    // MARK: - 데이터
    private var dataSection: some View {
        Section {
            Button("캐시 삭제") {
                viewModel.showClearCacheAlert = true
            }
            .alert("캐시 삭제", isPresented: $viewModel.showClearCacheAlert) {
                Button("삭제", role: .destructive) {
                    viewModel.clearCache()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("저장된 경기 데이터 캐시를 삭제합니다. 다시 불러오는데 시간이 걸릴 수 있습니다.")
            }
        } header: {
            Text("데이터")
        }
    }

    // MARK: - 앱 정보
    private var infoSection: some View {
        Section {
            HStack {
                Text("앱 버전")
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            HStack {
                Text("데이터 출처")
                Spacer()
                Text("ESPN")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        } header: {
            Text("정보")
        } footer: {
            Text("경기 데이터는 ESPN 비공식 API를 통해 제공됩니다. 실제 일정과 차이가 있을 수 있습니다.")
        }
    }
}

#Preview {
    SettingsView()
}
