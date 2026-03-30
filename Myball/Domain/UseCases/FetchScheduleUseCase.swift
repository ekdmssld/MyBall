// FetchScheduleUseCase.swift
// 월별 경기를 가져와서 내 팀 경기만 필터링하는 비즈니스 로직

import Foundation

// UseCase = 하나의 비즈니스 로직 단위
// Flutter의 UseCase 패턴과 동일한 개념
struct FetchScheduleUseCase {
    let repository: ScheduleRepositoryProtocol

    // 특정 월의 내 팀 경기만 필터링해서 반환
    // - team: 내 팀
    // - year: 연도
    // - month: 월
    // - returns: 내 팀 경기 배열 (날짜순 정렬)
    func execute(team: Team, year: Int, month: Int) async throws -> [Game] {
        // 1. 해당 월의 전체 경기를 가져옴
        let allGames = try await repository.fetchMonthGames(
            league: team.league,
            year: year,
            month: month
        )

        // 2. 내 팀 경기만 필터링
        // filter: 조건에 맞는 요소만 남김 (Flutter의 where와 비슷)
        let myGames = allGames.filter { game in
            game.homeTeam.teamId == team.id || game.awayTeam.teamId == team.id
        }

        // 3. 날짜순 정렬
        return myGames.sorted { $0.date < $1.date }
    }
}
