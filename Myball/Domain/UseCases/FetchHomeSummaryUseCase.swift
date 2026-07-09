// FetchHomeSummaryUseCase.swift
// 홈 화면에 필요한 데이터를 한 번에 만드는 비즈니스 로직
// 전월/당월/익월 3개월치를 가져와서 다음 경기, 최근 결과, 주간 일정, 월간 성적을 계산

import Foundation

// MARK: - 홈 화면 요약 데이터
struct HomeSummary: Equatable {
    let nextGame: Game?        // 다음 경기 (없으면 nil = 시즌 오프)
    let recentGames: [Game]    // 최근 종료된 5경기 (최신순)
    let weekGames: [Game]      // 오늘부터 7일간의 경기
    let monthRecord: TeamRecord  // 이번 달 성적
}

struct FetchHomeSummaryUseCase {
    let repository: ScheduleRepositoryProtocol

    // - team: 내 팀
    // - now: 기준 시각 (테스트에서 시간을 고정하기 위해 파라미터로 받음)
    func execute(team: Team, now: Date = Date()) async throws -> HomeSummary {
        let calendar = Calendar.current

        // async let: 세 달치를 동시에 요청 (Flutter의 Future.wait와 비슷)
        // 당월은 실패하면 에러를 던지고, 전월/익월은 실패해도 빈 배열로 계속 진행
        async let currentGames = fetchMonth(league: team.league, date: now)
        async let prevGames = fetchMonthSafely(league: team.league, date: now.addingMonths(-1))
        async let nextGames = fetchMonthSafely(league: team.league, date: now.addingMonths(1))

        let allGames = try await currentGames + prevGames + nextGames

        // 내 팀 경기만 필터링 + 중복 제거 + 날짜순 정렬
        var seenIds = Set<String>()
        let myGames = allGames
            .filter { $0.homeTeam.teamId == team.id || $0.awayTeam.teamId == team.id }
            .filter { seenIds.insert($0.id).inserted }  // insert().inserted: 처음 넣는 경우만 true
            .sorted { $0.date < $1.date }

        let startOfToday = calendar.startOfDay(for: now)

        // 1. 다음 경기: 오늘 이후의 첫 예정/진행 중 경기
        let nextGame = myGames.first { game in
            (game.status == .scheduled || game.status == .inProgress)
                && game.date >= startOfToday
        }

        // 2. 최근 결과: 종료된 경기 중 마지막 5개, 최신순으로 뒤집기
        let recentGames = Array(
            myGames
                .filter { $0.status == .final_ && $0.date <= now }
                .suffix(5)
                .reversed()
        )

        // 3. 이번 주 경기: 오늘부터 7일간
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: startOfToday)!
        let weekGames = myGames.filter { $0.date >= startOfToday && $0.date < weekEnd }

        // 4. 이번 달 성적
        let monthGames = myGames.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        let monthRecord = TeamRecord.compute(games: monthGames, myTeamId: team.id)

        return HomeSummary(
            nextGame: nextGame,
            recentGames: recentGames,
            weekGames: weekGames,
            monthRecord: monthRecord
        )
    }

    // MARK: - 월별 조회 헬퍼

    private func fetchMonth(league: League, date: Date) async throws -> [Game] {
        let calendar = Calendar.current
        return try await repository.fetchMonthGames(
            league: league,
            year: calendar.component(.year, from: date),
            month: calendar.component(.month, from: date)
        )
    }

    // 실패해도 앱이 죽지 않도록 빈 배열을 반환하는 버전
    // try? = 에러가 나면 nil로 바꿔줌 (Flutter의 try-catch에서 빈 값 반환과 비슷)
    private func fetchMonthSafely(league: League, date: Date) async -> [Game] {
        (try? await fetchMonth(league: league, date: date)) ?? []
    }
}
