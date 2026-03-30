// Constants.swift
// 앱 전체에서 사용하는 상수 모음

import Foundation

// enum으로 선언하면 인스턴스 생성을 막을 수 있음 (Flutter의 abstract class와 비슷)
enum Constants {
    // MARK: - App Group
    // 메인 앱과 위젯이 데이터를 공유하기 위한 App Group ID
    static let appGroupID = "group.com.myball.shared"

    // MARK: - UserDefaults Keys
    // 선택한 팀 정보를 저장하는 키
    static let selectedTeamIDKey = "selectedTeamID"
    static let selectedLeagueKey = "selectedLeague"

    // MARK: - ESPN API
    // ESPN 비공식 API 기본 URL
    static let espnBaseURL = "https://site.api.espn.com/apis/site/v2/sports/baseball"

    // 스코어보드 URL을 생성하는 함수
    // - league: "mlb" 또는 "kbo"
    // - date: "YYYYMMDD" 형식의 날짜 문자열
    static func scoreboardURL(league: String, date: String) -> String {
        "\(espnBaseURL)/\(league)/scoreboard?dates=\(date)"
    }

    // 팀 목록 URL
    static func teamsURL(league: String) -> String {
        "\(espnBaseURL)/\(league)/teams"
    }

    // MARK: - Cache
    // 캐시 만료 시간 (30분 = 1800초)
    static let cacheExpirationInterval: TimeInterval = 30 * 60
}
