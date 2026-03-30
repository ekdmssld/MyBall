// ESPNDTOs.swift
// ESPN API JSON 응답을 Swift struct로 매핑 (DTO = Data Transfer Object)
// Codable: JSON ↔ Swift 자동 변환 (Flutter의 fromJson/toJson과 비슷)

import Foundation

// MARK: - 스코어보드 최상위 응답
struct ESPNScoreboardResponse: Codable {
    let events: [ESPNEvent]?
}

// MARK: - 개별 경기 이벤트
struct ESPNEvent: Codable {
    let id: String
    let date: String                       // ISO 8601 형식 "2025-04-05T17:10Z"
    let competitions: [ESPNCompetition]?
}

// MARK: - 대결 정보
struct ESPNCompetition: Codable {
    let venue: ESPNVenue?
    let competitors: [ESPNCompetitor]?
    let status: ESPNStatus?
}

// MARK: - 경기장
struct ESPNVenue: Codable {
    let fullName: String?
}

// MARK: - 참가팀
struct ESPNCompetitor: Codable {
    let homeAway: String?                  // "home" 또는 "away"
    let winner: Bool?
    let team: ESPNTeam?
    let score: String?                     // 점수 (문자열, 예: "7")
}

// MARK: - 팀 정보
struct ESPNTeam: Codable {
    let id: String?
    let name: String?                      // "Tigers"
    let abbreviation: String?              // "DET"
    let displayName: String?               // "Detroit Tigers"
    let shortDisplayName: String?          // "Tigers"
    let color: String?                     // HEX (# 없이)
    let alternateColor: String?
    let logo: String?                      // 로고 URL
}

// MARK: - 경기 상태
struct ESPNStatus: Codable {
    let type: ESPNStatusType?
}

struct ESPNStatusType: Codable {
    let name: String?                      // "STATUS_FINAL", "STATUS_SCHEDULED" 등
    let description: String?               // "Final", "Scheduled" 등
}

// MARK: - 팀 목록 API 응답
struct ESPNTeamsResponse: Codable {
    let sports: [ESPNSport]?
}

struct ESPNSport: Codable {
    let leagues: [ESPNLeague]?
}

struct ESPNLeague: Codable {
    let teams: [ESPNTeamWrapper]?
}

struct ESPNTeamWrapper: Codable {
    let team: ESPNTeam?
}

// MARK: - Domain 모델 변환
// DTO → Domain 모델로 변환하는 메서드들
extension ESPNEvent {
    // ESPNEvent → Game 변환
    // league 파라미터가 필요한 이유: ESPN 응답에는 리그 정보가 없음
    func toDomain(league: League) -> Game? {
        guard let competition = competitions?.first,
              let competitors = competition.competitors,
              competitors.count >= 2 else { return nil }

        // 홈팀과 원정팀 분리
        let homeCompetitor = competitors.first(where: { $0.homeAway == "home" })
        let awayCompetitor = competitors.first(where: { $0.homeAway == "away" })

        guard let home = homeCompetitor, let away = awayCompetitor else { return nil }

        // ESPN 날짜 문자열 → Date 변환
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        // ESPN은 "Z" 접미사를 사용하는 ISO 8601 형식
        let gameDate = dateFormatter.date(from: date)
            ?? ISO8601DateFormatter().date(from: date)
            ?? Date()

        // 경기 상태 변환
        let statusName = competition.status?.type?.name ?? "STATUS_SCHEDULED"
        let gameStatus = GameStatus(espnStatusName: statusName)

        return Game(
            id: id,
            date: gameDate,
            homeTeam: home.toGameTeam(),
            awayTeam: away.toGameTeam(),
            venue: competition.venue?.fullName,
            status: gameStatus,
            league: league
        )
    }
}

extension ESPNCompetitor {
    // ESPNCompetitor → GameTeam 변환
    func toGameTeam() -> GameTeam {
        GameTeam(
            teamId: team?.id ?? "",
            name: team?.displayName ?? team?.name ?? "Unknown",
            abbreviation: team?.abbreviation ?? "???",
            logoURL: team?.logo,
            score: score,
            isWinner: winner ?? false
        )
    }
}
