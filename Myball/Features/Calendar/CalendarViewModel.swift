// CalendarViewModel.swift
// 캘린더 화면의 상태 관리 — 월 이동, 경기 로드, 날짜 선택

import SwiftUI
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {
    // MARK: - Published 상태
    @Published var currentMonth: Date = Date()       // 현재 표시 중인 월
    @Published var selectedDate: Date? = nil          // 선택한 날짜
    @Published var games: [Game] = []                 // 이번 달 경기 목록
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // MARK: - 의존성
    let team: Team
    private let useCase: FetchScheduleUseCase

    init(team: Team) {
        self.team = team
        self.useCase = FetchScheduleUseCase(repository: ScheduleRepository())
    }

    // MARK: - 경기 로드
    func loadGames() async {
        isLoading = true
        errorMessage = nil

        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentMonth)
        let month = calendar.component(.month, from: currentMonth)

        do {
            games = try await useCase.execute(team: team, year: year, month: month)
        } catch {
            errorMessage = error.localizedDescription
            games = []
        }

        isLoading = false
    }

    // MARK: - 월 이동
    func goToPreviousMonth() {
        currentMonth = currentMonth.addingMonths(-1)
        Task { await loadGames() }
    }

    func goToNextMonth() {
        currentMonth = currentMonth.addingMonths(1)
        Task { await loadGames() }
    }

    func goToToday() {
        currentMonth = Date()
        selectedDate = Date()
        Task { await loadGames() }
    }

    // MARK: - 특정 날짜의 경기 조회
    // 캘린더 셀에서 해당 날짜 경기를 표시하기 위해 사용
    func games(for date: Date) -> [Game] {
        games.filter { game in
            game.date.isSameDay(as: date)
        }
    }

    // 특정 날짜에 경기가 있는지 확인
    func hasGames(on date: Date) -> Bool {
        !games(for: date).isEmpty
    }

    // MARK: - 선택한 날짜의 경기
    var selectedDateGames: [Game] {
        guard let date = selectedDate else { return [] }
        return games(for: date)
    }

    // MARK: - 캘린더 그리드 데이터
    // 캘린더에 표시할 날짜 배열 (빈 칸 포함)
    // nil = 빈 칸 (이전 달/다음 달 영역)
    var calendarDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = currentMonth.startOfMonth

        // 해당 월 1일의 요일 (일=1 ~ 토=7)
        // 일요일 시작 캘린더에서 앞에 빈 칸 개수 = 요일 - 1
        let firstWeekday = currentMonth.firstWeekdayOfMonth
        let emptyDays = firstWeekday - 1

        let daysInMonth = currentMonth.daysInMonth

        var days: [Date?] = []

        // 앞쪽 빈 칸
        for _ in 0..<emptyDays {
            days.append(nil)
        }

        // 실제 날짜
        for day in 1...daysInMonth {
            if let date = calendar.date(from: DateComponents(
                year: calendar.component(.year, from: startOfMonth),
                month: calendar.component(.month, from: startOfMonth),
                day: day
            )) {
                days.append(date)
            }
        }

        return days
    }
}
