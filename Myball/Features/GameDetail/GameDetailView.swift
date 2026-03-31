// GameDetailView.swift
// 경기 상세 화면 — 양팀 정보, 스코어, 경기장, 시간 표시
// Phase 5에서 캘린더 추가 / 배경화면 기능 연결

import SwiftUI
import Kingfisher

struct GameDetailView: View {
    let game: Game
    let myTeamId: String

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.extraLarge) {
                // 경기 상태 배지
                statusBadge

                // 양팀 매치업
                matchupSection

                // 경기 정보
                gameInfoSection
            }
            .padding(Theme.Spacing.large)
        }
        .background(Theme.Colors.background)
        .navigationTitle("경기 상세")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 경기 상태 배지
    private var statusBadge: some View {
        Text(game.status.displayText)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor)
            .clipShape(Capsule())
    }

    // MARK: - 양팀 매치업 (원정 @ 홈)
    private var matchupSection: some View {
        VStack(spacing: Theme.Spacing.large) {
            HStack(spacing: Theme.Spacing.large) {
                // 원정팀
                teamColumn(game.awayTeam, isMyTeam: game.awayTeam.teamId == myTeamId)

                // 스코어 또는 VS
                scoreOrVS

                // 홈팀
                teamColumn(game.homeTeam, isMyTeam: game.homeTeam.teamId == myTeamId)
            }

            // 홈/원정 라벨
            HStack {
                Text("원정")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity)
                Spacer().frame(width: 80)
                Text("홈")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    // MARK: - 팀 열 (로고 + 이름 + 점수)
    private func teamColumn(_ gameTeam: GameTeam, isMyTeam: Bool) -> some View {
        VStack(spacing: Theme.Spacing.medium) {
            // 팀 로고
            teamLogoView(gameTeam)

            // 팀 이름
            Text(gameTeam.abbreviation)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.Colors.label)

            Text(gameTeam.name)
                .font(.system(size: 11))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // 내 팀 표시
            if isMyTeam {
                Text("MY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Theme.Colors.primary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
    }

    // 팀 로고 이미지
    @ViewBuilder
    private func teamLogoView(_ gameTeam: GameTeam) -> some View {
        if let logoURL = gameTeam.logoURL, let url = URL(string: logoURL) {
            KFImage(url)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
        } else {
            // 로고 없으면 약칭 표시
            let team = Team.find(by: gameTeam.teamId)
            Circle()
                .fill(team?.color ?? Theme.Colors.primary)
                .frame(width: 64, height: 64)
                .overlay(
                    Text(gameTeam.abbreviation.prefix(2))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
    }

    // MARK: - 스코어 또는 VS
    private var scoreOrVS: some View {
        VStack(spacing: 4) {
            if game.status == .final_ || game.status == .inProgress {
                // 점수 표시
                HStack(spacing: 8) {
                    Text(game.awayTeam.score ?? "-")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text(":")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Text(game.homeTeam.score ?? "-")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
            } else {
                Text("VS")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(width: 80)
    }

    // MARK: - 경기 정보 (날짜, 시간, 장소)
    private var gameInfoSection: some View {
        VStack(spacing: Theme.Spacing.medium) {
            infoRow(icon: "calendar", title: "날짜", value: game.date.koreanDateString)
            infoRow(icon: "clock", title: "시간", value: game.date.koreanTimeString)

            if let venue = game.venue {
                infoRow(icon: "mappin.circle", title: "경기장", value: venue)
            }

            infoRow(icon: "sportscourt", title: "리그", value: game.league.displayName)
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    // 정보 행
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: Theme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Theme.Colors.primary)
                .frame(width: 24)

            Text(title)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 50, alignment: .leading)

            Text(value)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.label)

            Spacer()
        }
    }

    // 경기 상태별 색상
    private var statusColor: Color {
        switch game.status {
        case .scheduled: return Theme.Colors.scheduled
        case .inProgress: return Theme.Colors.inProgress
        case .final_: return .secondary
        case .postponed, .canceled: return .orange
        }
    }
}

// MARK: - Preview용 샘플 데이터
#Preview {
    NavigationStack {
        GameDetailView(
            game: Game(
                id: "preview-1",
                date: Date(),
                homeTeam: GameTeam(
                    teamId: "10", name: "New York Yankees",
                    abbreviation: "NYY",
                    logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/nyy.png",
                    score: "5", isWinner: true
                ),
                awayTeam: GameTeam(
                    teamId: "2", name: "Boston Red Sox",
                    abbreviation: "BOS",
                    logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/bos.png",
                    score: "3", isWinner: false
                ),
                venue: "Yankee Stadium",
                status: .final_,
                league: .mlb
            ),
            myTeamId: "10"
        )
    }
}
