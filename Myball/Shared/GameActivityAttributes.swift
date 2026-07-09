// GameActivityAttributes.swift
// Live Activity(잠금화면 실시간 현황)에 표시할 데이터 정의
// ⚠️ 이 파일은 메인 앱과 위젯 익스텐션 양쪽 타겟에 모두 포함됨
//    (앱이 Activity를 시작하고, 위젯 익스텐션이 UI를 그리기 때문)

import ActivityKit
import Foundation

struct GameActivityAttributes: ActivityAttributes {
    // MARK: - 실시간으로 바뀌는 상태
    // ContentState = 경기 진행에 따라 계속 업데이트되는 부분
    public struct ContentState: Codable, Hashable {
        var statusInfo: String    // "3회말" 등 이닝 정보
        var homeScore: Int
        var awayScore: Int
        var balls: Int            // 볼
        var strikes: Int          // 스트라이크
        var outs: Int             // 아웃
        var base1: Bool           // 1루 주자
        var base2: Bool           // 2루 주자
        var base3: Bool           // 3루 주자
        var pitcherName: String?  // 현재 투수
        var batterName: String?   // 현재 타자
        var isFinished: Bool      // 경기 종료 여부
    }

    // MARK: - 경기 내내 바뀌지 않는 고정 정보
    var homeTeamName: String
    var awayTeamName: String
    var homeTeamCode: String   // SS, LT 등
    var awayTeamCode: String
    var myTeamColorHex: String // 내 팀 컬러 (위젯에서 강조색으로 사용)
    var myTeamIsHome: Bool     // 내 팀이 홈인지
    var stadium: String?       // 경기장
}
