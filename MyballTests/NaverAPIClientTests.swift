// NaverAPIClientTests.swift
// 네이버 스포츠 API 통합 테스트 — 실제 네트워크를 호출해서 파싱이 잘 되는지 확인
// 주의: 실제 API를 호출하므로 네트워크가 없으면 실패할 수 있음

import Testing
import Foundation
@testable import Myball

struct NaverAPIClientTests {

    @Test("오늘 KBO 경기 조회 및 파싱")
    func fetchTodayGame() async throws {
        let client = NaverAPIClient.shared

        // KBO 10개 팀 중 하나는 오늘 경기가 있을 가능성이 높음
        // (시즌 중에는 보통 5경기 = 10팀 전부)
        var foundAny = false
        for teamId in NaverAPIClient.teamIdToNaverCode.keys {
            if let info = try await client.fetchTodayGame(myTeamId: teamId) {
                foundAny = true
                // 필수 필드가 잘 파싱됐는지 확인
                #expect(!info.gameId.isEmpty)
                #expect(!info.homeTeamName.isEmpty)
                #expect(!info.awayTeamName.isEmpty)
                #expect(!info.statusCode.isEmpty)
                print("[통합테스트] \(teamId): \(info.awayTeamName) @ \(info.homeTeamName) — \(info.statusCode) \(info.statusInfo) \(info.awayScore):\(info.homeScore)")
                break
            }
        }
        // 시즌 오프면 경기가 없을 수도 있으므로 결과만 기록
        print("[통합테스트] 오늘 경기 발견 여부: \(foundAny)")
    }

    @Test("진행 중 경기의 실시간 상세 파싱 (루상 주자, 볼카운트)")
    func fetchLiveDetail() async throws {
        let client = NaverAPIClient.shared

        // 진행 중인 경기 찾기
        for teamId in NaverAPIClient.teamIdToNaverCode.keys {
            guard let info = try await client.fetchTodayGame(myTeamId: teamId),
                  info.isLive else { continue }

            let detail = try await client.fetchLiveDetail(gameId: info.gameId)
            #expect(detail != nil, "진행 중 경기는 실시간 상세가 있어야 함")

            if let detail = detail {
                // 볼카운트는 규칙상 범위가 정해져 있음
                #expect((0...3).contains(detail.balls))
                #expect((0...2).contains(detail.strikes))
                #expect((0...2).contains(detail.outs))
                print("[통합테스트] \(info.awayTeamName) @ \(info.homeTeamName) \(info.statusInfo)")
                print("[통합테스트] B\(detail.balls) S\(detail.strikes) O\(detail.outs) | 1루:\(detail.base1) 2루:\(detail.base2) 3루:\(detail.base3)")
                print("[통합테스트] 투수: \(detail.pitcherName ?? "?") / 타자: \(detail.batterName ?? "?")")
                print("[통합테스트] 스코어 \(detail.awayScore):\(detail.homeScore)")
            }
            return
        }
        print("[통합테스트] 현재 진행 중인 경기 없음 — 상세 검증 생략")
    }

    @Test("경기 전 선발투수 조회")
    func fetchStarters() async throws {
        let client = NaverAPIClient.shared

        for teamId in NaverAPIClient.teamIdToNaverCode.keys {
            guard let info = try await client.fetchTodayGame(myTeamId: teamId),
                  !info.canceled else { continue }

            let starters = try await client.fetchStarters(gameId: info.gameId)
            print("[통합테스트] \(info.awayTeamName) 선발: \(starters.away?.name ?? "미정") (ERA \(starters.away?.era ?? "-"))")
            print("[통합테스트] \(info.homeTeamName) 선발: \(starters.home?.name ?? "미정") (ERA \(starters.home?.era ?? "-"))")
            // 경기일에는 선발이 한 명 이상은 공개되어 있는 게 보통
            return
        }
    }
}
