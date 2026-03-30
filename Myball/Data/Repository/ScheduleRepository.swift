// ScheduleRepository.swift
// 캐시 확인 → API 호출 → 캐시 저장 흐름을 관리

import Foundation

// ScheduleRepositoryProtocol을 실제로 구현하는 클래스
final class ScheduleRepository: ScheduleRepositoryProtocol {
    private let apiClient = APIClient.shared
    private let cache = ScheduleCache.shared

    // MARK: - 특정 날짜의 경기 조회
    func fetchGames(league: League, date: Date) async throws -> [Game] {
        let dateString = date.espnDateString

        // 1. 캐시에서 먼저 확인
        if let cached = cache.get(league: league, date: dateString) {
            return cached
        }

        // 2. 캐시에 없으면 API 호출
        let games = try await apiClient.fetchScoreboard(league: league, date: date)

        // 3. 결과를 캐시에 저장
        cache.set(games: games, league: league, date: dateString)

        return games
    }

    // MARK: - 특정 월의 전체 경기 조회
    // 한 달치 경기를 가져오기 위해 매일 API를 호출하면 비효율적
    // → 해당 월의 각 날짜별로 호출하되, 캐시를 활용
    func fetchMonthGames(league: League, year: Int, month: Int) async throws -> [Game] {
        // 해당 월의 시작일과 일수 계산
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!

        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return []
        }

        let daysInMonth = startDate.daysInMonth
        var allGames: [Game] = []

        // 각 날짜별로 경기 조회 (캐시 히트가 많으면 빠름)
        // withThrowingTaskGroup: 여러 비동기 작업을 동시에 실행 (Flutter의 Future.wait과 비슷)
        try await withThrowingTaskGroup(of: [Game].self) { group in
            for day in 1...daysInMonth {
                guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                    continue
                }

                // 각 날짜를 병렬로 조회 (네트워크가 빠르면 동시에 여러 요청)
                group.addTask { [self] in
                    try await fetchGames(league: league, date: date)
                }
            }

            // 모든 결과 수집
            for try await games in group {
                allGames.append(contentsOf: games)
            }
        }

        // 중복 제거 (같은 경기가 다른 날짜에 포함될 수 있음)
        var seen = Set<String>()
        allGames = allGames.filter { game in
            if seen.contains(game.id) { return false }
            seen.insert(game.id)
            return true
        }

        return allGames.sorted { $0.date < $1.date }
    }
}
