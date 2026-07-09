// LiveGameViewModel.swift
// 라이브 경기 화면의 상태 관리 — 20초마다 자동 새로고침 (폴링)

import SwiftUI
import Combine

@MainActor
final class LiveGameViewModel: ObservableObject {
    // MARK: - 화면 단계
    // 하나의 enum으로 화면 상태를 표현 (Flutter의 sealed class 상태 패턴과 비슷)
    enum Phase: Equatable {
        case loading                 // 처음 로딩 중
        case noGame                  // 오늘 경기 없음
        case canceled                // 경기 취소 (우천 등)
        case before                  // 경기 시작 전 (선발 매치업 표시)
        case live                    // 진행 중 (실시간 현황 표시)
        case finished                // 경기 종료 (최종 스코어)
        case error(String)           // 로드 실패
    }

    // MARK: - Published 상태
    @Published var phase: Phase = .loading
    @Published var gameInfo: LiveGameInfo? = nil
    @Published var detail: LiveGameDetail? = nil
    @Published var homeStarter: StarterInfo? = nil
    @Published var awayStarter: StarterInfo? = nil
    @Published var lastUpdated: Date? = nil   // 마지막 갱신 시각

    // MARK: - 의존성
    let team: Team
    private let client = NaverAPIClient.shared

    // 새로고침 주기 (초)
    private let pollingInterval: UInt64 = 20

    init(team: Team) {
        self.team = team
    }

    // MARK: - 폴링 시작
    // 뷰의 .task에서 호출 → 뷰가 사라지면 Task가 자동 취소되어 폴링도 멈춤
    func startPolling() async {
        await refresh()

        // Task.isCancelled: 뷰가 사라지면 true가 됨
        while !Task.isCancelled {
            // 20초 대기 (nanoseconds 단위라 * 1_000_000_000)
            try? await Task.sleep(nanoseconds: pollingInterval * 1_000_000_000)
            guard !Task.isCancelled else { break }
            await refresh()
        }
    }

    // MARK: - 데이터 갱신
    func refresh() async {
        do {
            // 1. 오늘 내 팀 경기 찾기
            guard let info = try await client.fetchTodayGame(myTeamId: team.id) else {
                phase = .noGame
                return
            }
            gameInfo = info

            // 2. 상태에 따라 추가 데이터 로드
            if info.canceled {
                phase = .canceled
            } else if info.isBefore {
                // 경기 전: 선발투수 매치업
                let starters = try await client.fetchStarters(gameId: info.gameId)
                homeStarter = starters.home
                awayStarter = starters.away
                phase = .before
            } else if info.isLive {
                // 진행 중: 실시간 상세 (루상 주자, 볼카운트)
                detail = try await client.fetchLiveDetail(gameId: info.gameId)
                phase = .live
            } else {
                phase = .finished
            }

            lastUpdated = Date()
        } catch {
            // 이미 데이터가 있으면 유지, 처음부터 실패한 경우만 에러 표시
            if gameInfo == nil {
                phase = .error("실시간 데이터를 불러오지 못했습니다.\n\(error.localizedDescription)")
            }
        }
    }

    // MARK: - 내 팀이 홈인지
    var isMyTeamHome: Bool {
        guard let info = gameInfo else { return false }
        return NaverAPIClient.teamIdToNaverCode[team.id] == info.homeTeamCode
    }
}
