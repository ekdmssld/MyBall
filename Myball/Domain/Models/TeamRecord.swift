// TeamRecord.swift
// 팀 성적 모델 — 경기 목록에서 승/패/무를 집계

import Foundation

struct TeamRecord: Equatable {
    var wins = 0    // 승
    var losses = 0  // 패
    var draws = 0   // 무

    // 집계된 총 경기 수 (결과가 나온 경기만)
    var totalGames: Int {
        wins + losses + draws
    }

    // 승률 — KBO 공식 방식: 승 / (승 + 패), 무승부는 제외
    var winRate: Double {
        let decided = wins + losses
        guard decided > 0 else { return 0 }
        return Double(wins) / Double(decided)
    }

    // "0.625" 형식의 승률 문자열
    // String(format:)은 Flutter의 toStringAsFixed(3)과 비슷
    var winRateText: String {
        String(format: "%.3f", winRate)
    }

    // "5승 1무 3패" 형식
    var summaryText: String {
        "\(wins)승 \(draws)무 \(losses)패"
    }

    // MARK: - 경기 목록에서 성적 집계
    // static 메서드: TeamRecord.compute(...)로 호출 (Flutter의 factory와 비슷한 사용감)
    static func compute(games: [Game], myTeamId: String) -> TeamRecord {
        var record = TeamRecord()

        for game in games {
            // result()가 nil이면 (예정/취소 경기) 집계에서 제외
            switch game.result(myTeamId: myTeamId) {
            case .win: record.wins += 1
            case .loss: record.losses += 1
            case .draw: record.draws += 1
            case nil: break
            }
        }

        return record
    }
}
