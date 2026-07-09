// HomeDomainTests.swift
// 홈 대시보드 관련 Domain 로직 단위 테스트
// Swift Testing 프레임워크 사용 (@Test, #expect)
// Flutter의 test() + expect()와 비슷한 구조

import Testing
import Foundation
@testable import Myball

// MARK: - 테스트용 가짜 Repository
// 실제 네트워크 호출 없이 미리 정해둔 경기 목록을 반환
private struct MockScheduleRepository: ScheduleRepositoryProtocol {
    var games: [Game] = []

    func fetchGames(league: League, date: Date) async throws -> [Game] {
        games.filter { $0.date.isSameDay(as: date) }
    }

    func fetchMonthGames(league: League, year: Int, month: Int) async throws -> [Game] {
        let calendar = Calendar.current
        return games.filter {
            calendar.component(.year, from: $0.date) == year
                && calendar.component(.month, from: $0.date) == month
        }
    }
}

// MARK: - 테스트 데이터 생성 헬퍼
private func makeGame(
    id: String,
    daysFromNow: Int,
    now: Date,
    myTeamId: String = "kbo-samsung",
    myScore: String? = nil,
    oppScore: String? = nil,
    status: GameStatus = .scheduled,
    isMyTeamHome: Bool = true
) -> Game {
    let date = Calendar.current.date(byAdding: .day, value: daysFromNow, to: now)!

    let myTeam = GameTeam(
        teamId: myTeamId, name: "삼성 라이온즈", abbreviation: "SSL",
        logoURL: nil, score: myScore, isWinner: false
    )
    let opponent = GameTeam(
        teamId: "kbo-lg", name: "LG 트윈스", abbreviation: "LG",
        logoURL: nil, score: oppScore, isWinner: false
    )

    return Game(
        id: id,
        date: date,
        homeTeam: isMyTeamHome ? myTeam : opponent,
        awayTeam: isMyTeamHome ? opponent : myTeam,
        venue: "대구",
        status: status,
        league: .kbo
    )
}

// MARK: - Game.result() 테스트
struct GameResultTests {

    @Test("스코어가 더 높으면 승리")
    func winResult() {
        let now = Date()
        let game = makeGame(id: "1", daysFromNow: -1, now: now,
                            myScore: "5", oppScore: "3", status: .final_)
        #expect(game.result(myTeamId: "kbo-samsung") == .win)
    }

    @Test("스코어가 더 낮으면 패배")
    func lossResult() {
        let now = Date()
        let game = makeGame(id: "1", daysFromNow: -1, now: now,
                            myScore: "2", oppScore: "7", status: .final_)
        #expect(game.result(myTeamId: "kbo-samsung") == .loss)
    }

    @Test("동점이면 무승부 (KBO)")
    func drawResult() {
        let now = Date()
        let game = makeGame(id: "1", daysFromNow: -1, now: now,
                            myScore: "4", oppScore: "4", status: .final_)
        #expect(game.result(myTeamId: "kbo-samsung") == .draw)
    }

    @Test("예정된 경기는 결과가 nil")
    func scheduledGameHasNoResult() {
        let now = Date()
        let game = makeGame(id: "1", daysFromNow: 1, now: now, status: .scheduled)
        #expect(game.result(myTeamId: "kbo-samsung") == nil)
    }

    @Test("종료됐지만 스코어가 없으면 nil")
    func finalWithoutScoreHasNoResult() {
        let now = Date()
        let game = makeGame(id: "1", daysFromNow: -1, now: now, status: .final_)
        #expect(game.result(myTeamId: "kbo-samsung") == nil)
    }
}

// MARK: - TeamRecord 테스트
struct TeamRecordTests {

    @Test("승/패/무 집계")
    func computeRecord() {
        let now = Date()
        let games = [
            makeGame(id: "1", daysFromNow: -5, now: now, myScore: "5", oppScore: "3", status: .final_),
            makeGame(id: "2", daysFromNow: -4, now: now, myScore: "2", oppScore: "8", status: .final_),
            makeGame(id: "3", daysFromNow: -3, now: now, myScore: "4", oppScore: "4", status: .final_),
            makeGame(id: "4", daysFromNow: -2, now: now, myScore: "6", oppScore: "1", status: .final_),
            makeGame(id: "5", daysFromNow: 1, now: now, status: .scheduled),  // 예정 경기는 제외
        ]

        let record = TeamRecord.compute(games: games, myTeamId: "kbo-samsung")

        #expect(record.wins == 2)
        #expect(record.losses == 1)
        #expect(record.draws == 1)
        #expect(record.totalGames == 4)
    }

    @Test("승률은 무승부를 제외하고 계산 (KBO 방식)")
    func winRateExcludesDraws() {
        var record = TeamRecord()
        record.wins = 3
        record.losses = 1
        record.draws = 2

        // 3 / (3 + 1) = 0.75
        #expect(record.winRate == 0.75)
        #expect(record.winRateText == "0.750")
    }

    @Test("경기가 없으면 승률 0")
    func emptyRecordWinRate() {
        let record = TeamRecord()
        #expect(record.winRate == 0)
    }
}

// MARK: - FetchHomeSummaryUseCase 테스트
struct FetchHomeSummaryUseCaseTests {

    private let myTeam = Team.kboTeams[0]  // 삼성 라이온즈

    @Test("다음 경기는 오늘 이후 첫 예정 경기")
    func nextGameSelection() async throws {
        let now = Date()
        let repository = MockScheduleRepository(games: [
            makeGame(id: "past", daysFromNow: -3, now: now, myScore: "1", oppScore: "0", status: .final_),
            makeGame(id: "upcoming1", daysFromNow: 2, now: now, status: .scheduled),
            makeGame(id: "upcoming2", daysFromNow: 5, now: now, status: .scheduled),
        ])

        let useCase = FetchHomeSummaryUseCase(repository: repository)
        let summary = try await useCase.execute(team: myTeam, now: now)

        #expect(summary.nextGame?.id == "upcoming1")
    }

    @Test("최근 경기는 종료된 경기 최대 5개, 최신순")
    func recentGamesLimitAndOrder() async throws {
        let now = Date()
        // 종료된 경기 7개 생성 (-7일 ~ -1일)
        let finishedGames = (1...7).map { offset in
            makeGame(id: "g\(offset)", daysFromNow: -offset, now: now,
                     myScore: "3", oppScore: "1", status: .final_)
        }
        let repository = MockScheduleRepository(games: finishedGames)

        let useCase = FetchHomeSummaryUseCase(repository: repository)
        let summary = try await useCase.execute(team: myTeam, now: now)

        #expect(summary.recentGames.count == 5)
        // 최신순: 가장 최근 경기(-1일)가 첫 번째
        #expect(summary.recentGames.first?.id == "g1")
        #expect(summary.recentGames.last?.id == "g5")
    }

    @Test("이번 주 경기는 오늘부터 7일 이내만 포함")
    func weekGamesRange() async throws {
        let now = Date()
        let repository = MockScheduleRepository(games: [
            makeGame(id: "yesterday", daysFromNow: -1, now: now, status: .scheduled),
            makeGame(id: "today", daysFromNow: 0, now: now, status: .scheduled),
            makeGame(id: "in3days", daysFromNow: 3, now: now, status: .scheduled),
            makeGame(id: "in10days", daysFromNow: 10, now: now, status: .scheduled),
        ])

        let useCase = FetchHomeSummaryUseCase(repository: repository)
        let summary = try await useCase.execute(team: myTeam, now: now)

        let ids = summary.weekGames.map(\.id)
        #expect(ids.contains("today"))
        #expect(ids.contains("in3days"))
        #expect(!ids.contains("yesterday"))
        #expect(!ids.contains("in10days"))
    }

    @Test("다른 팀 경기는 요약에서 제외")
    func filtersOtherTeamsGames() async throws {
        let now = Date()
        // 내 팀과 무관한 경기 (LG vs 두산)
        let otherGame = Game(
            id: "other",
            date: Calendar.current.date(byAdding: .day, value: 1, to: now)!,
            homeTeam: GameTeam(teamId: "kbo-lg", name: "LG 트윈스", abbreviation: "LG",
                               logoURL: nil, score: nil, isWinner: false),
            awayTeam: GameTeam(teamId: "kbo-doosan", name: "두산 베어스", abbreviation: "OB",
                               logoURL: nil, score: nil, isWinner: false),
            venue: "잠실",
            status: .scheduled,
            league: .kbo
        )
        let repository = MockScheduleRepository(games: [otherGame])

        let useCase = FetchHomeSummaryUseCase(repository: repository)
        let summary = try await useCase.execute(team: myTeam, now: now)

        #expect(summary.nextGame == nil)
        #expect(summary.weekGames.isEmpty)
    }
}
