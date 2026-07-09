// LiveActivityService.swift
// 잠금화면 Live Activity의 시작/업데이트/종료를 관리하는 서비스
// 구조: 앱을 열었을 때 진행 중인 경기가 있으면 자동 시작
//       → 이후 폰을 잠가도 잠금화면 + Dynamic Island에 경기 현황이 계속 표시됨

import ActivityKit
import Foundation

@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()

    // 현재 실행 중인 Live Activity
    private var currentActivity: Activity<GameActivityAttributes>?
    private var currentGameId: String?

    private init() {
        // 앱 재시작 시 이전에 시작한 Activity가 남아있으면 다시 연결
        currentActivity = Activity<GameActivityAttributes>.activities.first
    }

    // MARK: - 자동 동기화 (홈 화면 로드 시 호출)
    // 진행 중 경기 → 시작/업데이트, 종료된 경기 → 종료 처리
    func autoSync(team: Team) async {
        guard team.league == .kbo else { return }  // 현재 KBO만 지원

        guard let info = try? await NaverAPIClient.shared.fetchTodayGame(myTeamId: team.id) else {
            return
        }

        if info.isLive {
            // try?는 중첩 옵셔널을 자동으로 한 겹으로 만들어줌
            if let detail = try? await NaverAPIClient.shared.fetchLiveDetail(gameId: info.gameId) {
                await startOrUpdate(info: info, detail: detail, team: team)
            }
        } else if info.isFinished {
            await end(info: info)
        }
    }

    // MARK: - 시작 또는 업데이트
    func startOrUpdate(info: LiveGameInfo, detail: LiveGameDetail, team: Team) async {
        // 사용자가 설정에서 Live Activity를 꺼놨으면 아무것도 안 함
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = makeState(info: info, detail: detail, isFinished: false)
        // staleDate: 이 시각이 지나면 iOS가 "오래된 정보" 표시를 함
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(10 * 60))

        // 이미 같은 경기의 Activity가 있으면 업데이트만
        if let activity = currentActivity, currentGameId == info.gameId || currentGameId == nil {
            currentGameId = info.gameId
            await activity.update(content)
            return
        }

        // 새로 시작
        let attributes = GameActivityAttributes(
            homeTeamName: info.homeTeamName,
            awayTeamName: info.awayTeamName,
            homeTeamCode: info.homeTeamCode,
            awayTeamCode: info.awayTeamCode,
            myTeamColorHex: team.colorHex,
            myTeamIsHome: NaverAPIClient.teamIdToNaverCode[team.id] == info.homeTeamCode,
            stadium: info.stadium
        )

        do {
            currentActivity = try Activity.request(attributes: attributes, content: content)
            currentGameId = info.gameId
            print("✅ Live Activity 시작: \(info.gameId)")
        } catch {
            // 시뮬레이터 미지원, 사용자 설정 등으로 실패할 수 있음 — 앱 동작에는 영향 없음
            print("⚠️ Live Activity 시작 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 종료 (최종 스코어 표시 후 30분 뒤 사라짐)
    func end(info: LiveGameInfo) async {
        guard let activity = currentActivity else { return }

        let finalState = GameActivityAttributes.ContentState(
            statusInfo: "경기 종료",
            homeScore: info.homeScore,
            awayScore: info.awayScore,
            balls: 0, strikes: 0, outs: 0,
            base1: false, base2: false, base3: false,
            pitcherName: nil, batterName: nil,
            isFinished: true
        )

        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .after(Date().addingTimeInterval(30 * 60))
        )
        currentActivity = nil
        currentGameId = nil
        print("🏁 Live Activity 종료")
    }

    // MARK: - 상태 변환 헬퍼
    private func makeState(info: LiveGameInfo, detail: LiveGameDetail, isFinished: Bool) -> GameActivityAttributes.ContentState {
        GameActivityAttributes.ContentState(
            statusInfo: info.statusInfo,
            homeScore: detail.homeScore,
            awayScore: detail.awayScore,
            balls: detail.balls,
            strikes: detail.strikes,
            outs: detail.outs,
            base1: detail.base1,
            base2: detail.base2,
            base3: detail.base3,
            pitcherName: detail.pitcherName,
            batterName: detail.batterName,
            isFinished: isFinished
        )
    }

    // MARK: - 테스트용 더미 Activity (#if DEBUG)
    // 실제 경기가 없어도 잠금화면 UI를 확인할 수 있음
    #if DEBUG
    func startDummy() async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activity가 비활성화되어 있습니다")
            return
        }

        let attributes = GameActivityAttributes(
            homeTeamName: "삼성",
            awayTeamName: "LG",
            homeTeamCode: "SS",
            awayTeamCode: "LG",
            myTeamColorHex: "074CA1",
            myTeamIsHome: true,
            stadium: "대구"
        )
        let state = GameActivityAttributes.ContentState(
            statusInfo: "7회말",
            homeScore: 5,
            awayScore: 3,
            balls: 2, strikes: 1, outs: 2,
            base1: true, base2: false, base3: true,
            pitcherName: "김테스트", batterName: "이더미",
            isFinished: false
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil)
            )
            currentGameId = "dummy"
            print("✅ 더미 Live Activity 시작됨 — 홈 화면으로 나가거나 잠금화면에서 확인하세요")
        } catch {
            print("⚠️ 더미 Live Activity 실패: \(error.localizedDescription)")
        }
    }

    func endDummy() async {
        guard let activity = currentActivity else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil
        currentGameId = nil
        print("🏁 더미 Live Activity 종료됨")
    }
    #endif
}
