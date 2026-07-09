// TeamStanding.swift
// KBO 팀 순위 모델 — 공식 사이트 순위표의 한 줄

import Foundation

struct TeamStanding: Identifiable, Equatable {
    let rank: Int          // 순위
    let teamId: String     // 우리 앱의 팀 ID (kbo-samsung 등)
    let teamName: String   // 팀 이름 (삼성, LG 등)
    let games: Int         // 경기 수
    let wins: Int          // 승
    let losses: Int        // 패
    let draws: Int         // 무
    let winRate: String    // 승률 (예: "0.610")
    let gamesBehind: String // 1위와의 게임차 ("-"면 1위)
    let streak: String     // 연속 기록 (예: "3승", "1패")

    var id: String { teamId }

    // "50승 2무 32패" 형식
    var recordText: String {
        "\(wins)승 \(draws)무 \(losses)패"
    }
}
