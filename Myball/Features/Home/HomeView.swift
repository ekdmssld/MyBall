// HomeView.swift
// 홈 대시보드 — 다음 경기 카드, 이번 달 성적, 최근 결과, 이번 주 일정
// Flutter의 SingleChildScrollView + Column 구조와 비슷

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    init(team: Team) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(team: team))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("불러오는 중...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if let summary = viewModel.summary {
                    summaryScrollView(summary)
                }
            }
            .navigationTitle("홈")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.load()
            }
        }
    }

    // MARK: - 메인 스크롤 뷰
    private func summaryScrollView(_ summary: HomeSummary) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.large) {
                // 1. 다음 경기 카드
                if let nextGame = summary.nextGame {
                    NavigationLink {
                        GameDetailView(game: nextGame, myTeamId: viewModel.team.id)
                    } label: {
                        NextGameCard(
                            game: nextGame,
                            team: viewModel.team,
                            dDayText: viewModel.dDayText(for: nextGame)
                        )
                    }
                    .buttonStyle(.plain)  // 링크 파란색 틴트 방지
                } else {
                    noGameCard
                }

                // 1.5. 오늘 경기가 있으면 라이브 경기 센터 배너 (KBO만 지원)
                if viewModel.team.league == .kbo,
                   let todayGame = summary.nextGame,
                   todayGame.date.isToday {
                    NavigationLink {
                        LiveGameView(team: viewModel.team)
                    } label: {
                        LiveCenterBanner(isLive: todayGame.status == .inProgress)
                    }
                    .buttonStyle(.plain)
                }

                // 2. 이번 달 성적
                MonthRecordSection(record: summary.monthRecord)

                // 2.5. 리그 순위 (KBO)
                if !viewModel.standings.isEmpty {
                    StandingsSection(
                        standings: viewModel.standings,
                        myTeamId: viewModel.team.id,
                        myTeamColor: viewModel.team.color
                    )
                }

                // 3. 최근 5경기
                RecentGamesSection(
                    games: summary.recentGames,
                    myTeamId: viewModel.team.id
                )

                // 4. 이번 주 경기
                WeekGamesSection(
                    games: summary.weekGames,
                    myTeamId: viewModel.team.id
                )
            }
            .padding(Theme.Spacing.large)
        }
        .refreshable {
            await viewModel.load()
        }
    }

    // MARK: - 다음 경기 없음 (시즌 오프)
    private var noGameCard: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 36))
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text("예정된 경기가 없습니다")
                .font(Theme.Fonts.headline)
            Text("시즌이 시작되면 다음 경기가 여기에 표시됩니다")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.extraLarge)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    // MARK: - 에러 화면
    private func errorView(_ message: String) -> some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(message)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
            Button("다시 시도") {
                Task { await viewModel.load() }
            }
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Theme.Colors.primary)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 라이브 경기 센터 배너
// 오늘 경기가 있을 때 실시간 현황 화면으로 이동하는 배너
private struct LiveCenterBanner: View {
    let isLive: Bool  // 경기 진행 중 여부

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            if isLive {
                // 진행 중: 빨간 LIVE 점
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("LIVE")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.red)
                Text("실시간 경기 현황 보기")
                    .font(.system(size: 14, weight: .semibold))
            } else {
                Image(systemName: "sportscourt")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.primary)
                Text("경기 센터 · 오늘의 선발 매치업 보기")
                    .font(.system(size: 14, weight: .semibold))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(Theme.Spacing.large)
        .background(isLive ? Color.red.opacity(0.08) : Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }
}

// MARK: - 다음 경기 카드
private struct NextGameCard: View {
    let game: Game
    let team: Team
    let dDayText: String

    var body: some View {
        let opponent = game.opponent(myTeamId: team.id)
        let isHome = game.isHome(teamId: team.id)

        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            // 상단: "다음 경기" 라벨 + D-day 뱃지
            HStack {
                Text("다음 경기")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Text(dDayText)
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.25))
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
            }

            // 중앙: 상대팀
            HStack(spacing: Theme.Spacing.medium) {
                Text(isHome ? "vs" : "@")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                Text(opponent.name)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            // 하단: 날짜/시간/장소 + 홈/원정
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(game.date.koreanDateString) \(game.date.koreanTimeString)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    if let venue = game.venue {
                        Text(venue)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                Spacer()

                Text(isHome ? "홈" : "원정")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding(Theme.Spacing.large)
        .background(
            // 팀 컬러 그라데이션 배경
            LinearGradient(
                colors: [team.color, team.color.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }
}

// MARK: - 이번 달 성적 섹션
private struct MonthRecordSection: View {
    let record: TeamRecord

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("이번 달 성적")
                .font(Theme.Fonts.headline)

            if record.totalGames == 0 {
                Text("아직 결과가 나온 경기가 없습니다")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Theme.Spacing.medium)
            } else {
                HStack(spacing: 0) {
                    statColumn(value: "\(record.wins)", label: "승", color: .red)
                    statColumn(value: "\(record.draws)", label: "무", color: Theme.Colors.secondaryLabel)
                    statColumn(value: "\(record.losses)", label: "패", color: .blue)
                    statColumn(value: record.winRateText, label: "승률", color: Theme.Colors.label)
                }
            }
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    private func statColumn(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 리그 순위 섹션
private struct StandingsSection: View {
    let standings: [TeamStanding]
    let myTeamId: String
    let myTeamColor: Color

    // 내 팀의 순위 정보
    private var myStanding: TeamStanding? {
        standings.first { $0.teamId == myTeamId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("리그 순위")
                .font(Theme.Fonts.headline)

            // 내 팀 요약 (크게)
            if let mine = myStanding {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.medium) {
                    Text("\(mine.rank)위")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(myTeamColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(mine.recordText + " · 승률 \(mine.winRate)")
                            .font(.system(size: 13, weight: .semibold))
                        Text(mine.gamesBehind == "-"
                             ? "리그 1위! · 최근 \(mine.streak)"
                             : "1위와 \(mine.gamesBehind)경기차 · 최근 \(mine.streak)")
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }

                    Spacer()
                }
                .padding(.bottom, Theme.Spacing.small)
            }

            // 전체 순위표 (컴팩트)
            VStack(spacing: 0) {
                ForEach(standings) { standing in
                    standingRow(standing)
                }
            }
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    private func standingRow(_ standing: TeamStanding) -> some View {
        let isMine = standing.teamId == myTeamId

        return HStack(spacing: Theme.Spacing.medium) {
            Text("\(standing.rank)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(isMine ? myTeamColor : Theme.Colors.secondaryLabel)
                .frame(width: 18, alignment: .center)

            Text(standing.teamName)
                .font(.system(size: 13, weight: isMine ? .bold : .regular))

            Spacer()

            Text(standing.recordText)
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.secondaryLabel)

            Text(standing.winRate)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .frame(width: 44, alignment: .trailing)

            Text(standing.gamesBehind)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, Theme.Spacing.small)
        .background(isMine ? myTeamColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
    }
}

// MARK: - 최근 5경기 섹션
private struct RecentGamesSection: View {
    let games: [Game]
    let myTeamId: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("최근 경기")
                .font(Theme.Fonts.headline)

            if games.isEmpty {
                Text("최근 경기 결과가 없습니다")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Theme.Spacing.medium)
            } else {
                ForEach(games) { game in
                    NavigationLink {
                        GameDetailView(game: game, myTeamId: myTeamId)
                    } label: {
                        recentGameRow(game)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    private func recentGameRow(_ game: Game) -> some View {
        let opponent = game.opponent(myTeamId: myTeamId)
        let result = game.result(myTeamId: myTeamId)

        return HStack(spacing: Theme.Spacing.medium) {
            // 승/패/무 뱃지
            Text(result?.displayText ?? "-")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(resultColor(result))
                .clipShape(Circle())

            // 날짜
            Text(game.date.koreanDateString)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 80, alignment: .leading)

            // 상대팀
            Text(opponent.name)
                .font(Theme.Fonts.teamName)
                .lineLimit(1)

            Spacer()

            // 스코어
            if let score = game.scoreText {
                Text(score)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
            }
        }
        .padding(.vertical, Theme.Spacing.small)
    }

    // 승=빨강, 패=파랑, 무=회색 (한국 야구 관례)
    private func resultColor(_ result: GameResult?) -> Color {
        switch result {
        case .win: return .red
        case .loss: return .blue
        case .draw, nil: return .gray
        }
    }
}

// MARK: - 이번 주 경기 섹션
private struct WeekGamesSection: View {
    let games: [Game]
    let myTeamId: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("이번 주 경기")
                .font(Theme.Fonts.headline)

            if games.isEmpty {
                Text("이번 주에는 경기가 없습니다")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Theme.Spacing.medium)
            } else {
                ForEach(games) { game in
                    NavigationLink {
                        GameDetailView(game: game, myTeamId: myTeamId)
                    } label: {
                        weekGameRow(game)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    private func weekGameRow(_ game: Game) -> some View {
        let opponent = game.opponent(myTeamId: myTeamId)
        let isHome = game.isHome(teamId: myTeamId)

        return HStack(spacing: Theme.Spacing.medium) {
            // 날짜 + 시간
            VStack(alignment: .leading, spacing: 2) {
                Text(game.date.koreanDateString)
                    .font(.system(size: 13, weight: .semibold))
                Text(game.date.koreanTimeString)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .frame(width: 90, alignment: .leading)

            // 상대팀
            HStack(spacing: 4) {
                Text(isHome ? "vs" : "@")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(opponent.name)
                    .font(Theme.Fonts.teamName)
                    .lineLimit(1)
            }

            Spacer()

            // 홈/원정 or 결과
            if game.status == .final_, let score = game.scoreText {
                Text(score)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
            } else {
                Text(isHome ? "홈" : "원정")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isHome ? Theme.Colors.home : Theme.Colors.away)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, Theme.Spacing.small)
    }
}

#Preview {
    HomeView(team: Team.kboTeams[0])
}
