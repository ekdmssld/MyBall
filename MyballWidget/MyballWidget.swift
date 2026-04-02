// MyballWidget.swift
// MyBall 위젯 — Small / Medium / Large 3가지 크기 지원
// 다음 경기 정보와 이번 주 일정을 홈화면에서 바로 확인

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
// 위젯에 표시할 데이터를 담는 구조체
struct GameEntry: TimelineEntry {
    let date: Date                    // 타임라인 시점
    let team: WidgetTeam?             // 선택된 팀 (없으면 팀 선택 안내)
    let nextGame: WidgetGame?         // 다음 경기
    let upcomingGames: [WidgetGame]   // 이번 주 경기 목록
    let isKBO: Bool                   // KBO 팀 여부 (API 미지원 안내용)
}

// MARK: - Timeline Provider
// 위젯의 데이터를 제공하는 프로바이더
// placeholder → 스켈레톤 표시
// getSnapshot → 위젯 갤러리 미리보기
// getTimeline → 실제 데이터 로드 + 30분 후 리프레시
struct GameTimelineProvider: TimelineProvider {
    // UserDefaults에서 선택된 팀 읽기
    private func loadTeam() -> WidgetTeam? {
        let defaults = UserDefaults(suiteName: WidgetConstants.appGroupID) ?? .standard
        guard let teamId = defaults.string(forKey: WidgetConstants.selectedTeamIDKey) else {
            return nil
        }
        return WidgetTeam.find(by: teamId)
    }

    // placeholder: 로딩 중 표시 (실제 데이터 없이 레이아웃만)
    func placeholder(in context: Context) -> GameEntry {
        GameEntry(
            date: Date(),
            team: WidgetTeam.mlbTeams.first,
            nextGame: nil,
            upcomingGames: [],
            isKBO: false
        )
    }

    // snapshot: 위젯 갤러리에서 미리보기 표시
    func getSnapshot(in context: Context, completion: @escaping (GameEntry) -> Void) {
        let team = loadTeam()
        let entry = GameEntry(
            date: Date(),
            team: team,
            nextGame: nil,
            upcomingGames: [],
            isKBO: team?.league == .kbo
        )
        completion(entry)
    }

    // timeline: 실제 데이터를 로드하고 타임라인 생성
    func getTimeline(in context: Context, completion: @escaping (Timeline<GameEntry>) -> Void) {
        Task {
            let team = loadTeam()

            guard let team = team else {
                // 팀이 선택되지 않은 경우
                let entry = GameEntry(date: Date(), team: nil, nextGame: nil, upcomingGames: [], isKBO: false)
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30)))
                completion(timeline)
                return
            }

            // KBO: 공식 사이트 API / MLB: ESPN API
            let games = await WidgetAPIClient.fetchUpcomingGames(team: team, days: 7)

            // 다음 경기 = 현재 시각 이후의 예정된 경기 중 가장 빠른 것
            let now = Date()
            let nextGame = games.first(where: { $0.date > now && $0.isScheduled })

            let entry = GameEntry(
                date: Date(),
                team: team,
                nextGame: nextGame,
                upcomingGames: Array(games.prefix(5)),
                isKBO: false
            )

            // 30분 후 리프레시
            let refreshDate = Date().addingTimeInterval(60 * 30)
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

// MARK: - 위젯 정의
struct MyballWidget: Widget {
    let kind: String = "MyballWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GameTimelineProvider()) { entry in
            MyballWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    if let team = entry.team {
                        LinearGradient(
                            colors: [team.color.opacity(0.15), team.altColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(.systemBackground)
                    }
                }
        }
        .configurationDisplayName("MyBall")
        .description("응원하는 팀의 다음 경기 일정을 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 위젯 Entry View (크기별 분기)
struct MyballWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: GameEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small 위젯
// 팀 이름 + 다음 경기 (상대팀, 날짜/시간, 홈/원정)
struct SmallWidgetView: View {
    let entry: GameEntry

    var body: some View {
        if let team = entry.team {
            VStack(alignment: .leading, spacing: 6) {
                // 팀 이름
                HStack(spacing: 4) {
                    Circle()
                        .fill(team.color)
                        .frame(width: 14, height: 14)
                    Text(team.shortName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                }

                if entry.isKBO {
                    Spacer()
                    Text("KBO 데이터\n준비 중")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                } else if let game = entry.nextGame {
                    Spacer()
                    // 상대팀
                    Text(game.opponentAbbr(myTeamId: team.id))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    // 홈/원정
                    Text(game.isHome(teamId: team.id) ? "vs (홈)" : "@ (원정)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(game.isHome(teamId: team.id) ? team.color : .secondary)

                    // 날짜/시간
                    Text(game.shortDateString)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(game.koreanTimeString)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.primary)
                } else {
                    Spacer()
                    Text("예정된\n경기 없음")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            // 팀 미선택 상태
            VStack(spacing: 8) {
                Image(systemName: "baseball")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                Text("앱에서 팀을\n선택해주세요")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Medium 위젯
// 왼쪽: 다음 경기 상세 / 오른쪽: 이번 주 경기 리스트 (최대 3개)
struct MediumWidgetView: View {
    let entry: GameEntry

    var body: some View {
        if let team = entry.team {
            HStack(spacing: 12) {
                // 왼쪽: 다음 경기
                nextGameSection(team: team)
                    .frame(maxWidth: .infinity)

                // 구분선
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1)
                    .padding(.vertical, 4)

                // 오른쪽: 이번 주 경기 목록
                upcomingSection(team: team)
                    .frame(maxWidth: .infinity)
            }
        } else {
            noTeamView
        }
    }

    private func nextGameSection(team: WidgetTeam) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // 팀 헤더
            HStack(spacing: 4) {
                Circle()
                    .fill(team.color)
                    .frame(width: 12, height: 12)
                Text(team.shortName)
                    .font(.system(size: 12, weight: .bold))
            }

            if entry.isKBO {
                Spacer()
                Text("KBO 데이터 준비 중")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
            } else if let game = entry.nextGame {
                Spacer()
                Text("NEXT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(team.color)

                Text(game.opponentAbbr(myTeamId: team.id))
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text(game.isHome(teamId: team.id) ? "vs (홈)" : "@ (원정)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("\(game.shortDateString) \(game.koreanTimeString)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let venue = game.venue {
                    Text(venue)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            } else {
                Spacer()
                Text("예정된 경기 없음")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    private func upcomingSection(team: WidgetTeam) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("이번 주")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            if entry.upcomingGames.isEmpty {
                Spacer()
                Text("경기 없음")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(Array(entry.upcomingGames.prefix(3).enumerated()), id: \.offset) { _, game in
                    HStack(spacing: 4) {
                        // 홈/원정 마크
                        Circle()
                            .fill(game.isHome(teamId: team.id) ? team.color : .secondary.opacity(0.5))
                            .frame(width: 6, height: 6)

                        Text(game.opponentAbbr(myTeamId: team.id))
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 32, alignment: .leading)

                        Text(game.shortDateString)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var noTeamView: some View {
        HStack {
            Image(systemName: "baseball")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("앱에서 팀을 선택해주세요")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Large 위젯
// 팀 헤더 + 다음 경기 하이라이트 + 주간 경기 리스트 (최대 5개)
struct LargeWidgetView: View {
    let entry: GameEntry

    var body: some View {
        if let team = entry.team {
            VStack(alignment: .leading, spacing: 8) {
                // 팀 헤더
                teamHeader(team: team)

                if entry.isKBO {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                            Text("KBO 리그 데이터는\n현재 제공되지 않습니다")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    Spacer()
                } else {
                    // 다음 경기 하이라이트
                    if let game = entry.nextGame {
                        nextGameCard(game: game, team: team)
                    }

                    // 주간 경기 리스트
                    weeklyGamesList(team: team)

                    Spacer(minLength: 0)
                }
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "baseball")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text("앱에서 응원하는 팀을\n선택해주세요")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func teamHeader(team: WidgetTeam) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(team.color)
                .frame(width: 16, height: 16)
            Text(team.shortName)
                .font(.system(size: 15, weight: .bold))
            Spacer()
            Text(team.league.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.quaternary)
                .clipShape(Capsule())
        }
    }

    private func nextGameCard(game: WidgetGame, team: WidgetTeam) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("NEXT GAME")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(team.color)

                Text(game.opponentName(myTeamId: team.id))
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)

                Text(game.isHome(teamId: team.id) ? "vs (홈)" : "@ (원정)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(game.shortDateString)
                    .font(.system(size: 12, weight: .medium))
                Text(game.koreanTimeString)
                    .font(.system(size: 14, weight: .bold))
                if let venue = game.venue {
                    Text(venue)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(10)
        .background(team.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func weeklyGamesList(team: WidgetTeam) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("이번 주 일정")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            if entry.upcomingGames.isEmpty {
                Text("예정된 경기가 없습니다")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(entry.upcomingGames.prefix(5).enumerated()), id: \.offset) { _, game in
                    gameRow(game: game, team: team)
                }
            }
        }
    }

    private func gameRow(game: WidgetGame, team: WidgetTeam) -> some View {
        HStack(spacing: 8) {
            // 홈/원정 표시
            Circle()
                .fill(game.isHome(teamId: team.id) ? team.color : .secondary.opacity(0.5))
                .frame(width: 8, height: 8)

            // 상대팀
            Text(game.opponentAbbr(myTeamId: team.id))
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 36, alignment: .leading)

            // 날짜
            Text(game.shortDateString)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            // 시간 또는 스코어
            if game.isFinal, let score = game.scoreText {
                Text(score)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            } else {
                Text(game.koreanTimeString)
                    .font(.system(size: 11, weight: .medium))
            }

            // 홈/원정 라벨
            Text(game.isHome(teamId: team.id) ? "홈" : "원정")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(game.isHome(teamId: team.id) ? team.color : .secondary)
                .frame(width: 24)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    MyballWidget()
} timeline: {
    GameEntry(
        date: Date(),
        team: WidgetTeam.mlbTeams[2], // Yankees
        nextGame: WidgetGame(
            id: "preview-1",
            date: Date().addingTimeInterval(3600 * 24),
            homeTeamId: "10", homeTeamName: "New York Yankees", homeTeamAbbr: "NYY",
            awayTeamId: "2", awayTeamName: "Boston Red Sox", awayTeamAbbr: "BOS",
            venue: "Yankee Stadium",
            homeScore: nil, awayScore: nil,
            statusName: "STATUS_SCHEDULED"
        ),
        upcomingGames: [],
        isKBO: false
    )
}

#Preview(as: .systemMedium) {
    MyballWidget()
} timeline: {
    GameEntry(
        date: Date(),
        team: WidgetTeam.mlbTeams[2],
        nextGame: WidgetGame(
            id: "preview-1",
            date: Date().addingTimeInterval(3600 * 24),
            homeTeamId: "10", homeTeamName: "New York Yankees", homeTeamAbbr: "NYY",
            awayTeamId: "2", awayTeamName: "Boston Red Sox", awayTeamAbbr: "BOS",
            venue: "Yankee Stadium",
            homeScore: nil, awayScore: nil,
            statusName: "STATUS_SCHEDULED"
        ),
        upcomingGames: [
            WidgetGame(id: "p1", date: Date().addingTimeInterval(3600*24), homeTeamId: "10", homeTeamName: "Yankees", homeTeamAbbr: "NYY", awayTeamId: "2", awayTeamName: "Red Sox", awayTeamAbbr: "BOS", venue: nil, homeScore: nil, awayScore: nil, statusName: "STATUS_SCHEDULED"),
            WidgetGame(id: "p2", date: Date().addingTimeInterval(3600*48), homeTeamId: "14", homeTeamName: "Blue Jays", homeTeamAbbr: "TOR", awayTeamId: "10", awayTeamName: "Yankees", awayTeamAbbr: "NYY", venue: nil, homeScore: nil, awayScore: nil, statusName: "STATUS_SCHEDULED"),
        ],
        isKBO: false
    )
}
