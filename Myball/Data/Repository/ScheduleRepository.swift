// ScheduleRepository.swift
// 캐시 확인 → API 호출 → 캐시 저장 흐름을 관리 (KBO 전용)

import Foundation

// ScheduleRepositoryProtocol을 실제로 구현하는 클래스
final class ScheduleRepository: ScheduleRepositoryProtocol {
    private let kboClient = KBOAPIClient.shared
    private let cache = ScheduleCache.shared

    // MARK: - 특정 날짜의 경기 조회
    // 해당 월 전체를 가져온 뒤 그 날짜의 경기만 필터링
    func fetchGames(league: League, date: Date) async throws -> [Game] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)

        let monthGames = try await fetchMonthGames(league: league, year: year, month: month)
        return monthGames.filter { $0.date.isSameDay(as: date) }
    }

    // MARK: - 특정 월의 전체 경기 조회
    // KBO 공식 사이트 API는 한 번 호출로 월별 전체를 반환
    func fetchMonthGames(league: League, year: Int, month: Int) async throws -> [Game] {
        let cacheKey = "\(year)\(String(format: "%02d", month))"

        // 1. 캐시에서 먼저 확인
        if let cached = cache.get(league: league, date: cacheKey) {
            return cached
        }

        // 2. 캐시에 없으면 API 호출
        let games = try await kboClient.fetchMonthSchedule(year: year, month: month)

        // 3. 결과를 캐시에 저장
        cache.set(games: games, league: league, date: cacheKey)

        return games
    }
}
