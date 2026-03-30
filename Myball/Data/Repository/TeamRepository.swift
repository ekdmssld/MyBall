// TeamRepository.swift
// 사용자가 선택한 팀 정보를 UserDefaults에 저장/불러오기

import Foundation

final class TeamRepository: TeamRepositoryProtocol {
    // App Group을 사용하는 UserDefaults
    // suiteName으로 App Group ID를 지정하면 위젯과 데이터 공유 가능
    // (Flutter의 shared_preferences와 비슷하지만 App Group으로 확장)
    private let defaults: UserDefaults

    init() {
        // App Group UserDefaults — 위젯과 공유
        // 실패 시 일반 UserDefaults로 폴백
        self.defaults = UserDefaults(suiteName: Constants.appGroupID) ?? .standard
    }

    // MARK: - 선택한 팀 불러오기
    func getSelectedTeam() -> Team? {
        // UserDefaults에서 팀 ID를 가져옴
        guard let teamId = defaults.string(forKey: Constants.selectedTeamIDKey) else {
            return nil
        }
        // ID로 팀 데이터 검색
        return Team.find(by: teamId)
    }

    // MARK: - 선택한 팀 저장
    func saveSelectedTeam(_ team: Team) {
        defaults.set(team.id, forKey: Constants.selectedTeamIDKey)
        defaults.set(team.league.rawValue, forKey: Constants.selectedLeagueKey)
    }

    // MARK: - 선택한 리그 불러오기
    func getSelectedLeague() -> League? {
        guard let rawValue = defaults.string(forKey: Constants.selectedLeagueKey) else {
            return nil
        }
        return League(rawValue: rawValue)
    }

    // MARK: - 리그 저장
    func saveSelectedLeague(_ league: League) {
        defaults.set(league.rawValue, forKey: Constants.selectedLeagueKey)
    }

    // MARK: - 선택한 팀 초기화
    func clearSelectedTeam() {
        defaults.removeObject(forKey: Constants.selectedTeamIDKey)
        defaults.removeObject(forKey: Constants.selectedLeagueKey)
    }
}
