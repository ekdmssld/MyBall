// LiveGame.swift
// 실시간 경기 현황 모델 — 네이버 스포츠 API 데이터를 담는 구조체들

import Foundation

// MARK: - 경기 기본 정보 (오늘 경기 목록에서 가져옴)
struct LiveGameInfo: Equatable {
    let gameId: String        // 네이버 경기 ID (예: "20260708HTLT02026")
    let statusCode: String    // BEFORE(시작 전) / STARTED(진행 중) / RESULT(종료)
    let statusInfo: String    // "3회말", "경기취소", "18:30" 등 상태 설명
    let homeTeamCode: String  // 홈팀 코드 (SS, LT 등)
    let homeTeamName: String  // 홈팀 이름 (삼성, 롯데 등)
    let awayTeamCode: String
    let awayTeamName: String
    let homeScore: Int
    let awayScore: Int
    let stadium: String?      // 경기장
    let gameDateTime: Date?   // 경기 시작 시각
    let canceled: Bool        // 우천 취소 등

    // 편의 상태 판별 프로퍼티들
    var isBefore: Bool { statusCode == "BEFORE" && !canceled }
    var isLive: Bool { statusCode == "STARTED" }
    var isFinished: Bool { statusCode == "RESULT" }
}

// MARK: - 실시간 상세 상태 (문자중계 API에서 가져옴)
struct LiveGameDetail: Equatable {
    let balls: Int        // 볼 카운트
    let strikes: Int      // 스트라이크
    let outs: Int         // 아웃
    let base1: Bool       // 1루 주자 유무
    let base2: Bool       // 2루 주자 유무
    let base3: Bool       // 3루 주자 유무
    let pitcherName: String?  // 현재 투수
    let batterName: String?   // 현재 타자
    let homeScore: Int
    let awayScore: Int
}

// MARK: - 선발투수 정보 (경기 전 미리보기 API에서 가져옴)
struct StarterInfo: Equatable {
    let name: String      // 선수 이름
    let era: String?      // 시즌 평균자책점 (예: "3.95")
}
