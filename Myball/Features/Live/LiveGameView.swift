// LiveGameView.swift
// 라이브 경기 화면 — 실시간 스코어, 다이아몬드(루상 주자), 볼카운트, 선발투수
// 네이버 스포츠의 경기 현황 화면과 비슷한 구성

import SwiftUI

struct LiveGameView: View {
    @StateObject private var viewModel: LiveGameViewModel

    init(team: Team) {
        _viewModel = StateObject(wrappedValue: LiveGameViewModel(team: team))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.large) {
                switch viewModel.phase {
                case .loading:
                    ProgressView("경기 정보를 불러오는 중...")
                        .padding(.top, 100)

                case .noGame:
                    emptyState(icon: "moon.zzz", message: "오늘은 경기가 없습니다")

                case .canceled:
                    if let info = viewModel.gameInfo {
                        scoreboardHeader(info)
                    }
                    emptyState(icon: "cloud.rain", message: "경기가 취소되었습니다")

                case .before:
                    if let info = viewModel.gameInfo {
                        scoreboardHeader(info)
                        starterMatchupSection(info)
                    }

                case .live:
                    if let info = viewModel.gameInfo {
                        scoreboardHeader(info)
                        if let detail = viewModel.detail {
                            liveFieldSection(detail)
                            currentPlayersSection(detail)
                        }
                    }

                case .finished:
                    if let info = viewModel.gameInfo {
                        scoreboardHeader(info)
                        emptyState(icon: "checkmark.circle", message: "경기가 종료되었습니다")
                    }

                case .error(let message):
                    emptyState(icon: "exclamationmark.triangle", message: message)
                }

                // 마지막 갱신 시각
                if let updated = viewModel.lastUpdated, viewModel.phase == .live {
                    Text("마지막 갱신: \(updated.koreanTimeString) · 20초마다 자동 갱신")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .padding(Theme.Spacing.large)
        }
        .navigationTitle("경기 센터")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.refresh()
        }
        // 뷰가 보이는 동안 폴링, 사라지면 자동 중단
        .task {
            await viewModel.startPolling()
        }
    }

    // MARK: - 스코어보드 헤더 (원정 vs 홈 + 상태)
    private func scoreboardHeader(_ info: LiveGameInfo) -> some View {
        VStack(spacing: Theme.Spacing.medium) {
            // 상태 뱃지 (LIVE / 시작 전 / 종료)
            statusBadge(info)

            HStack(spacing: Theme.Spacing.large) {
                // 원정팀
                teamColumn(name: info.awayTeamName, code: info.awayTeamCode)

                // 스코어
                if info.isBefore {
                    Text(info.gameDateTime?.koreanTimeString ?? "-")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                } else {
                    // 진행 중에는 문자중계의 스코어가 더 정확함
                    let away = viewModel.detail?.awayScore ?? info.awayScore
                    let home = viewModel.detail?.homeScore ?? info.homeScore
                    Text("\(away) : \(home)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                }

                // 홈팀
                teamColumn(name: info.homeTeamName, code: info.homeTeamCode)
            }

            if let stadium = info.stadium {
                Text("\(stadium) 구장")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    private func teamColumn(name: String, code: String) -> some View {
        VStack(spacing: 6) {
            // 팀 컬러 원 (내 팀이면 팀 컬러, 상대팀이면 회색)
            let isMyTeam = NaverAPIClient.teamIdToNaverCode[viewModel.team.id] == code
            Circle()
                .fill(isMyTeam ? viewModel.team.color : Color.gray.opacity(0.4))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(code)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                )
            Text(name)
                .font(Theme.Fonts.teamName)
        }
        .frame(width: 80)
    }

    private func statusBadge(_ info: LiveGameInfo) -> some View {
        HStack(spacing: 5) {
            if info.isLive {
                // 빨간 점 (LIVE 표시)
                Circle()
                    .fill(.red)
                    .frame(width: 7, height: 7)
                Text("LIVE · \(info.statusInfo)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.red)
            } else {
                Text(info.isBefore ? "경기 예정" : info.statusInfo)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(info.isLive ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - 실시간 필드 (다이아몬드 + 볼카운트)
    private func liveFieldSection(_ detail: LiveGameDetail) -> some View {
        HStack(spacing: Theme.Spacing.extraLarge) {
            // 다이아몬드 (루상 주자)
            baseDiamond(detail)

            // 볼카운트 (B/S/O)
            VStack(alignment: .leading, spacing: 10) {
                countRow(label: "B", count: detail.balls, max: 3, color: .green)
                countRow(label: "S", count: detail.strikes, max: 2, color: .yellow)
                countRow(label: "O", count: detail.outs, max: 2, color: .red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    // 다이아몬드 모양 루상 주자 표시
    // 사각형 3개를 45도 회전시켜 야구장 베이스 모양으로 배치
    private func baseDiamond(_ detail: LiveGameDetail) -> some View {
        ZStack {
            baseSquare(occupied: detail.base2)          // 2루 (위)
                .offset(y: -26)
            baseSquare(occupied: detail.base3)          // 3루 (왼쪽)
                .offset(x: -26)
            baseSquare(occupied: detail.base1)          // 1루 (오른쪽)
                .offset(x: 26)
        }
        .frame(width: 110, height: 90)
    }

    private func baseSquare(occupied: Bool) -> some View {
        Rectangle()
            .fill(occupied ? viewModel.team.color : Color.gray.opacity(0.25))
            .frame(width: 26, height: 26)
            .rotationEffect(.degrees(45))  // 45도 회전 = 다이아몬드 모양
            .animation(.easeInOut(duration: 0.3), value: occupied)
    }

    // B/S/O 카운트 점 표시 (예: B ●●○)
    private func countRow(label: String, count: Int, max: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 16)

            ForEach(0..<max, id: \.self) { index in
                Circle()
                    .fill(index < count ? color : Color.gray.opacity(0.25))
                    .frame(width: 12, height: 12)
            }
        }
    }

    // MARK: - 현재 투수/타자
    private func currentPlayersSection(_ detail: LiveGameDetail) -> some View {
        HStack(spacing: 0) {
            playerColumn(role: "투수", name: detail.pitcherName, icon: "figure.baseball")
            Divider().frame(height: 40)
            playerColumn(role: "타자", name: detail.batterName, icon: "figure.softball")
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    private func playerColumn(role: String, name: String?, icon: String) -> some View {
        VStack(spacing: 4) {
            Text(role)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(name ?? "-")
                .font(.system(size: 17, weight: .bold))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 선발투수 매치업 (경기 전)
    private func starterMatchupSection(_ info: LiveGameInfo) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("선발 매치업")
                .font(Theme.Fonts.headline)

            HStack(spacing: 0) {
                starterColumn(teamName: info.awayTeamName, starter: viewModel.awayStarter)

                Text("VS")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Theme.Colors.secondaryLabel)

                starterColumn(teamName: info.homeTeamName, starter: viewModel.homeStarter)
            }
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    private func starterColumn(teamName: String, starter: StarterInfo?) -> some View {
        VStack(spacing: 4) {
            Text(teamName)
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(starter?.name ?? "미정")
                .font(.system(size: 17, weight: .bold))
            if let era = starter?.era {
                Text("ERA \(era)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 빈 상태 표시
    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(message)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}

#Preview {
    NavigationStack {
        LiveGameView(team: Team.kboTeams[0])
    }
}
