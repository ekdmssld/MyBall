// ScheduleRepository.swift
// 캐시 확인 → API 호출 → 캐시 저장 흐름을 관리

import Foundation

// ScheduleRepositoryProtocol을 실제로 구현하는 클래스
final class ScheduleRepository: ScheduleRepositoryProtocol {
    private let apiClient = APIClient.shared
    private let kboClient = KBOAPIClient.shared
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
    func fetchMonthGames(league: League, year: Int, month: Int) async throws -> [Game] {
        switch league {
        case .kbo:
            return try await fetchKBOMonthGames(year: year, month: month)
        case .mlb:
            return try await fetchMLBMonthGames(year: year, month: month)
        }
    }

    // MARK: - KBO: 공식 사이트 API (한 번 호출로 월별 전체 조회)
    private func fetchKBOMonthGames(year: Int, month: Int) async throws -> [Game] {
        let cacheKey = "\(year)\(String(format: "%02d", month))"

        // 캐시 확인
        if let cached = cache.get(league: .kbo, date: cacheKey) {
            return cached
        }

        let games = try await kboClient.fetchMonthSchedule(year: year, month: month)

        // 캐시 저장
        cache.set(games: games, league: .kbo, date: cacheKey)

        return games
    }

    // MARK: - MLB: ESPN API (날짜별 병렬 조회)
    private func fetchMLBMonthGames(year: Int, month: Int) async throws -> [Game] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!

        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return []
        }

        let daysInMonth = startDate.daysInMonth
        typealias DayResult = [Game]?

        var allGames: [Game] = []
        var successCount = 0

        // withTaskGroup (non-throwing): 개별 날짜 실패가 전체를 중단시키지 않음
        await withTaskGroup(of: DayResult.self) { group in
            for day in 1...daysInMonth {
                guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                    continue
                }

                group.addTask { [self] in
                    do {
                        return try await fetchGames(league: .mlb, date: date)
                    } catch {
                        return nil
                    }
                }
            }

            for await result in group {
                if let games = result {
                    successCount += 1
                    allGames.append(contentsOf: games)
                }
            }
        }

        if successCount == 0 {
            throw APIError.noData
        }

        // 중복 제거
        var seen = Set<String>()
        allGames = allGames.filter { game in
            if seen.contains(game.id) { return false }
            seen.insert(game.id)
            return true
        }

        return allGames.sorted { $0.date < $1.date }
    }
}
