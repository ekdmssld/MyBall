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

    // MARK: - 승패 판정

    // 내 팀 기준 경기 결과 (승/패/무)
    // 경기가 끝나지 않았거나 스코어가 없으면 nil 반환
    // 옵셔널 반환 = Flutter에서 nullable 타입(GameResult?)을 반환하는 것과 같음
    func result(myTeamId: String) -> GameResult? {
        guard status == .final_,
              let myScoreText = myTeam(myTeamId: myTeamId).score,
              let oppScoreText = opponent(myTeamId: myTeamId).score,
              let myScore = Int(myScoreText),
              let oppScore = Int(oppScoreText) else {
            return nil
        }

        if myScore > oppScore { return .win }
        if myScore < oppScore { return .loss }
        return .draw  // KBO는 무승부가 존재함
    }
}

// MARK: - 경기 결과 (내 팀 기준)
enum GameResult {
    case win   // 승
    case loss  // 패
    case draw  // 무승부

    var displayText: String {
        switch self {
        case .win: return "승"
        case .loss: return "패"
        case .draw: return "무"
        }
    }
}
