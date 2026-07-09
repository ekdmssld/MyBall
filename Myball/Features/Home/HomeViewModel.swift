// HomeViewModel.swift
// 홈 화면의 상태 관리 — 요약 데이터 로드, D-day 계산

import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published 상태
    @Published var summary: HomeSummary? = nil
    // 처음부터 true로 시작해야 함!
    // false면 첫 렌더링 때 (로딩도 아니고, 에러도 없고, 데이터도 없는) 상태가 되어
    // 화면에 아무 뷰도 없는 EmptyView가 되는데, EmptyView에는 .task가 실행되지 않아
    // 데이터 로드가 영영 시작되지 않는 버그가 생김
    @Published var isLoading = true
    @Published var errorMessage: String? = nil

    // MARK: - 의존성
    let team: Team
    private let useCase: FetchHomeSummaryUseCase

    init(team: Team) {
        self.team = team
        self.useCase = FetchHomeSummaryUseCase(repository: ScheduleRepository())
    }

    // MARK: - 데이터 로드
    func load() async {
        // 이미 데이터가 있으면 로딩 표시 없이 조용히 갱신 (pull-to-refresh 대응)
        if summary == nil {
            isLoading = true
        }
        errorMessage = nil

        do {
            summary = try await useCase.execute(team: team)
        } catch {
            // 기존 데이터가 있으면 유지하고, 없을 때만 에러 화면 표시
            if summary == nil {
                errorMessage = "데이터를 불러오지 못했습니다.\n\(error.localizedDescription)"
            }
        }

        isLoading = false
    }

    // MARK: - D-day 텍스트
    // 경기까지 남은 날짜를 "오늘", "내일", "D-3" 형식으로 변환
    func dDayText(for game: Game) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: game.date)
        ).day ?? 0

        switch days {
        case 0: return "오늘"
        case 1: return "내일"
        default: return "D-\(days)"
        }
    }
}
