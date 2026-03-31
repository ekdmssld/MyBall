// CalendarMainView.swift
// 캘린더 메인 화면 — 월별 그리드 + 경기 표시
// Flutter의 TableCalendar와 비슷한 역할

import SwiftUI
import Kingfisher

struct CalendarMainView: View {
    @StateObject private var viewModel: CalendarViewModel

    // 외부에서 team을 받아 ViewModel 초기화
    // Flutter의 widget 생성자와 비슷
    init(team: Team) {
        // _viewModel: StateObject의 내부 저장 프로퍼티에 직접 접근
        _viewModel = StateObject(wrappedValue: CalendarViewModel(team: team))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 월 네비게이션 헤더
                monthHeader

                // 요일 헤더 (일 ~ 토)
                weekdayHeader

                // 캘린더 그리드
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("경기 일정을 불러오는 중...")
                    Spacer()
                } else {
                    calendarGrid
                }

                // 선택한 날짜의 경기 목록
                selectedDateGameList
            }
            .navigationTitle(viewModel.team.shortName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    teamBadge
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("오늘") { viewModel.goToToday() }
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .task {
                // task: 뷰가 나타날 때 자동 실행 (Flutter의 initState + API 호출)
                await viewModel.loadGames()
            }
        }
    }

    // MARK: - 팀 배지 (네비게이션 바 왼쪽)
    private var teamBadge: some View {
        HStack(spacing: 6) {
            if let logoURL = viewModel.team.logoURL, let url = URL(string: logoURL) {
                KFImage(url)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Circle()
                    .fill(viewModel.team.color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(viewModel.team.abbreviation.prefix(2))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
        }
    }

    // MARK: - 월 네비게이션
    private var monthHeader: some View {
        HStack {
            Button { viewModel.goToPreviousMonth() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(viewModel.currentMonth.yearMonthString)
                .font(Theme.Fonts.title)

            Spacer()

            Button { viewModel.goToNextMonth() } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
    }

    // MARK: - 요일 헤더
    private var weekdayHeader: some View {
        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
        return HStack(spacing: 0) {
            ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                Text(day)
                    .font(Theme.Fonts.calendarDay)
                    .foregroundStyle(weekdayColor(for: index))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Theme.Spacing.small)
        .padding(.vertical, Theme.Spacing.small)
        .background(Theme.Colors.secondaryBackground)
    }

    // MARK: - 캘린더 그리드
    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return ScrollView {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(viewModel.calendarDays.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            games: viewModel.games(for: date),
                            isSelected: viewModel.selectedDate?.isSameDay(as: date) == true,
                            isToday: date.isToday,
                            teamId: viewModel.team.id
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedDate = date
                            }
                        }
                    } else {
                        // 빈 칸
                        Color.clear
                            .frame(height: 72)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.small)
        }
    }

    // MARK: - 선택한 날짜의 경기 목록
    @ViewBuilder
    private var selectedDateGameList: some View {
        if let selectedDate = viewModel.selectedDate {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                // 날짜 표시
                Text(selectedDate.koreanDateString)
                    .font(Theme.Fonts.headline)
                    .padding(.horizontal, Theme.Spacing.large)
                    .padding(.top, Theme.Spacing.medium)

                let dayGames = viewModel.selectedDateGames

                if dayGames.isEmpty {
                    Text("이 날은 경기가 없습니다")
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.large)
                } else {
                    ForEach(dayGames) { game in
                        NavigationLink(destination: GameDetailView(game: game, myTeamId: viewModel.team.id)) {
                            GameListRow(game: game, myTeamId: viewModel.team.id)
                        }
                    }
                }
            }
            .background(Theme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .padding(.horizontal, Theme.Spacing.small)
            .padding(.bottom, Theme.Spacing.small)
        }
    }

    // 요일별 색상 (일=빨강, 토=파랑, 평일=기본)
    private func weekdayColor(for index: Int) -> Color {
        switch index {
        case 0: return Theme.Colors.sunday
        case 6: return Theme.Colors.saturday
        default: return Theme.Colors.secondaryLabel
        }
    }
}

// MARK: - 캘린더 날짜 셀
private struct CalendarDayCell: View {
    let date: Date
    let games: [Game]
    let isSelected: Bool
    let isToday: Bool
    let teamId: String

    var body: some View {
        VStack(spacing: 2) {
            // 날짜 숫자
            Text("\(Calendar.current.component(.day, from: date))")
                .font(Theme.Fonts.calendarDay)
                .foregroundStyle(dayNumberColor)
                .frame(width: 28, height: 28)
                .background(dayBackground)
                .clipShape(Circle())

            // 경기 정보 (있는 경우)
            if let game = games.first {
                gameIndicator(game)
            } else {
                // 빈 공간 유지 (레이아웃 안정)
                Color.clear.frame(height: 32)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(isSelected ? Theme.Colors.primary.opacity(0.08) : Color.clear)
    }

    // 경기 표시 (상대팀 약칭 + 홈/원정)
    private func gameIndicator(_ game: Game) -> some View {
        let opponent = game.opponent(myTeamId: teamId)
        let isHome = game.isHome(teamId: teamId)

        return VStack(spacing: 0) {
            // 상대팀 약칭
            Text(opponent.abbreviation)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.Colors.label)

            // 홈/원정 표시 + 스코어 (경기 종료 시)
            if game.status == .final_, let score = game.scoreText {
                Text(score)
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                Text(isHome ? "홈" : "원정")
                    .font(.system(size: 8))
                    .foregroundStyle(isHome ? Theme.Colors.primary : Theme.Colors.scheduled)
            }
        }
        .frame(height: 32)
    }

    // 날짜 숫자 색상
    private var dayNumberColor: Color {
        let weekday = Calendar.current.component(.weekday, from: date)
        if isToday { return .white }
        switch weekday {
        case 1: return Theme.Colors.sunday
        case 7: return Theme.Colors.saturday
        default: return Theme.Colors.label
        }
    }

    // 오늘 / 선택 날짜 배경
    @ViewBuilder
    private var dayBackground: some View {
        if isToday {
            Theme.Colors.primary
        } else {
            Color.clear
        }
    }
}

// MARK: - 경기 목록 행 (선택한 날짜 하단)
private struct GameListRow: View {
    let game: Game
    let myTeamId: String

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            // 상태 표시 점
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            // 시간
            Text(game.date.koreanTimeString)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 60, alignment: .leading)

            // 상대팀
            VStack(alignment: .leading, spacing: 2) {
                let opponent = game.opponent(myTeamId: myTeamId)
                let isHome = game.isHome(teamId: myTeamId)

                HStack(spacing: 4) {
                    Text(isHome ? "vs" : "@")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Text(opponent.name)
                        .font(Theme.Fonts.teamName)
                        .foregroundStyle(Theme.Colors.label)
                }

                if let venue = game.venue {
                    Text(venue)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }

            Spacer()

            // 스코어 (경기 종료 시)
            if game.status == .final_, let score = game.scoreText {
                Text(score)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.Colors.label)
            } else {
                Text(game.status.displayText)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(statusColor)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
    }

    private var statusColor: Color {
        switch game.status {
        case .scheduled: return Theme.Colors.scheduled
        case .inProgress: return Theme.Colors.inProgress
        case .final_: return Theme.Colors.final_
        case .postponed, .canceled: return Theme.Colors.scheduled
        }
    }
}

#Preview {
    CalendarMainView(team: Team.mlbTeams[0])
}
