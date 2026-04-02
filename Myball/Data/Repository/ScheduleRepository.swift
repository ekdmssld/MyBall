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
    // 해당 월의 각 날짜별로 API를 호출하되, 캐시를 활용
    // 개별 날짜 실패는 무시하고 성공한 날짜의 경기만 수집
    func fetchMonthGames(league: League, year: Int, month: Int) async throws -> [Game] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!

        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return []
        }

        let daysInMonth = startDate.daysInMonth

        // 각 태스크의 결과: 성공(경기 배열) 또는 실패(nil)
        // nil = API 에러, 빈 배열 = 그 날 경기가 없음 (정상)
        typealias DayResult = [Game]?

        var allGames: [Game] = []
        var successCount = 0

        // withTaskGroup (non-throwing): 개별 날짜 실패가 전체를 중단시키지 않음
        // 이전에는 withThrowingTaskGroup을 사용해서 1개 실패 시 전체가 실패했음
        await withTaskGroup(of: DayResult.self) { group in
            for day in 1...daysInMonth {
                guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                    continue
                }

                group.addTask { [self] in
                    do {
                        return try await fetchGames(league: league, date: date)
                    } catch {
                        // 개별 날짜 실패는 nil로 처리 (다른 날짜에 영향 없음)
                        return nil
                    }
                }
            }

            // 모든 결과 수집
            for await result in group {
                if let games = result {
                    successCount += 1
                    allGames.append(contentsOf: games)
                }
            }
        }

        // 성공한 날짜가 하나도 없으면 API 문제
        if successCount == 0 {
            throw APIError.noData
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
