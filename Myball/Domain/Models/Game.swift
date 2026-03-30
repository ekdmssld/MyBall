// Game.swift
// 경기 모델 — 하나의 야구 경기를 나타냄

import Foundation

// MARK: - 경기 상태
// Flutter의 enum과 비슷하지만 raw value를 가질 수 있음
enum GameStatus: String, Codable {
    case scheduled   // 예정됨
    case inProgress  // 진행 중
    case final_      // 종료 (final은 Swift 예약어라 _ 붙임)
    case postponed   // 연기
    case canceled    // 취소

    // ESPN API의 status.type.name 값으로부터 변환
    init(espnStatusName: String) {
        switch espnStatusName {
        case "STATUS_SCHEDULED", "STATUS_WARMUP":
            self = .scheduled
        case "STATUS_IN_PROGRESS", "STATUS_RAIN_DELAY", "STATUS_DELAYED",
             "STATUS_PLAY_SUSPENDED":
            self = .inProgress
        case "STATUS_FINAL":
            self = .final_
        case "STATUS_POSTPONED":
            self = .postponed
        case "STATUS_CANCELED":
            self = .canceled
        default:
            self = .scheduled
        }
    }

    var displayText: String {
        switch self {
        case .scheduled: return "예정"
        case .inProgress: return "진행 중"
        case .final_: return "종료"
        case .postponed: return "연기"
        case .canceled: return "취소"
        }
    }
}

// MARK: - 경기에 참여하는 팀 정보
struct GameTeam: Codable, Equatable {
    let teamId: String       // ESPN 팀 ID
    let name: String         // 팀 전체 이름
    let abbreviation: String // 약칭 (DET, NYY 등)
    let logoURL: String?     // 로고 이미지 URL
    let score: String?       // 점수 (경기 전에는 nil)
    let isWinner: Bool       // 승리팀 여부
}

// MARK: - 경기 모델
struct Game: Identifiable, Codable, Equatable {
    let id: String           // ESPN 경기 ID
    let date: Date           // 경기 시작 시간 (UTC)
    let homeTeam: GameTeam   // 홈팀
    let awayTeam: GameTeam   // 원정팀
    let venue: String?       // 경기장 이름
    let status: GameStatus   // 경기 상태
    let league: League       // KBO / MLB

    // MARK: - 헬퍼 메서드

    // 내 팀이 홈인지 확인
    // - teamId: 내 팀의 ESPN ID
    func isHome(teamId: String) -> Bool {
        homeTeam.teamId == teamId
    }

    // 내 팀의 상대팀 반환
    func opponent(myTeamId: String) -> GameTeam {
        if homeTeam.teamId == myTeamId {
            return awayTeam
        } else {
            return homeTeam
        }
    }

    // 내 팀 정보 반환
    func myTeam(myTeamId: String) -> GameTeam {
        if homeTeam.teamId == myTeamId {
            return homeTeam
        } else {
            return awayTeam
        }
    }

    // 스코어 요약 텍스트 (예: "7 - 2")
    var scoreText: String? {
        guard let homeScore = homeTeam.score,
              let awayScore = awayTeam.score else { return nil }
        return "\(awayScore) - \(homeScore)"
    }
}
