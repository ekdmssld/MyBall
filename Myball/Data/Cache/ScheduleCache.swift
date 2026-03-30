// ScheduleCache.swift
// 인메모리 캐시 — API 호출을 줄이기 위해 경기 데이터를 메모리에 저장

import Foundation

// MARK: - 캐시 항목
// 캐시된 데이터와 저장 시간을 함께 보관
private struct CacheEntry {
    let games: [Game]
    let timestamp: Date     // 캐시 저장 시간

    // 캐시가 만료되었는지 확인 (30분 후 만료)
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > Constants.cacheExpirationInterval
    }
}

// MARK: - 스케줄 캐시
// final: 상속 불가 (Flutter에서 final class와 동일)
// Sendable: 동시성(concurrency) 안전 — 여러 스레드에서 접근 가능
final class ScheduleCache: @unchecked Sendable {
    static let shared = ScheduleCache()

    // NSLock: 여러 스레드가 동시에 캐시에 접근하는 것을 방지
    // (Flutter에서는 Dart가 싱글 스레드라 필요 없지만, Swift는 멀티 스레드)
    private let lock = NSLock()

    // 캐시 저장소 — 키: "mlb-20250405", 값: CacheEntry
    private var cache: [String: CacheEntry] = [:]

    private init() {}

    // MARK: - 캐시 키 생성
    // 리그 + 날짜 조합으로 유니크한 키 생성
    private func cacheKey(league: League, date: String) -> String {
        "\(league.rawValue)-\(date)"
    }

    // MARK: - 캐시에서 데이터 가져오기
    // 만료되지 않은 캐시가 있으면 반환, 없으면 nil
    func get(league: League, date: String) -> [Game]? {
        lock.lock()
        defer { lock.unlock() }  // defer: 함수 종료 시 반드시 실행 (Flutter의 finally)

        let key = cacheKey(league: league, date: date)
        guard let entry = cache[key], !entry.isExpired else {
            // 만료된 캐시는 삭제
            cache.removeValue(forKey: key)
            return nil
        }
        return entry.games
    }

    // MARK: - 캐시에 데이터 저장
    func set(games: [Game], league: League, date: String) {
        lock.lock()
        defer { lock.unlock() }

        let key = cacheKey(league: league, date: date)
        cache[key] = CacheEntry(games: games, timestamp: Date())
    }

    // MARK: - 캐시 전체 삭제 (설정에서 사용)
    func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
}
