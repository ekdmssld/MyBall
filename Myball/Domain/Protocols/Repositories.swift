// Repositories.swift
// Repository 프로토콜 (인터페이스) 정의
// Flutter의 abstract class와 비슷 — 실제 구현은 Data 레이어에서 함

import Foundation

// MARK: - 경기 일정 저장소
// protocol = Flutter의 abstract class (구현 없이 메서드 시그니처만 정의)
protocol ScheduleRepositoryProtocol {
    // 특정 리그, 특정 날짜의 경기 목록 조회
    func fetchGames(league: League, date: Date) async throws -> [Game]

    // 특정 리그, 특정 월의 경기 목록 조회 (캘린더에서 사용)
    func fetchMonthGames(league: League, year: Int, month: Int) async throws -> [Game]
}

// MARK: - 팀 저장소
protocol TeamRepositoryProtocol {
    // 저장된 마이팀 불러오기 (없으면 nil)
    func getSelectedTeam() -> Team?

    // 마이팀 저장
    func saveSelectedTeam(_ team: Team)

    // 저장된 리그 불러오기
    func getSelectedLeague() -> League?

    // 리그 저장
    func saveSelectedLeague(_ league: League)

    // 마이팀 초기화 (설정에서 변경 시)
    func clearSelectedTeam()
}
