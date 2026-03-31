// TeamSelectionViewModel.swift
// 팀 선택 화면의 상태 관리
// ViewModel = Flutter의 ChangeNotifier / Riverpod Provider와 비슷

import SwiftUI
import Combine

// @MainActor: 모든 프로퍼티 변경이 메인 스레드에서 실행됨 (UI 업데이트 안전)
// ObservableObject: SwiftUI가 이 객체의 변경을 감시 (Flutter의 ChangeNotifier)
@MainActor
final class TeamSelectionViewModel: ObservableObject {
    // @Published: 값이 바뀌면 SwiftUI가 자동으로 화면을 다시 그림
    // (Flutter의 notifyListeners()를 자동으로 호출하는 것과 비슷)
    @Published var selectedLeague: League = .kbo
    @Published var searchText: String = ""

    private let teamRepository = TeamRepository()

    // 현재 선택된 리그의 팀 목록 (검색 필터 적용)
    var filteredTeams: [Team] {
        let teams = Team.teams(for: selectedLeague)

        // 검색어가 비어있으면 전체 반환
        if searchText.isEmpty { return teams }

        // 팀 이름에 검색어가 포함된 팀만 필터링 (대소문자 무시)
        return teams.filter { team in
            team.name.localizedCaseInsensitiveContains(searchText) ||
            team.shortName.localizedCaseInsensitiveContains(searchText) ||
            team.abbreviation.localizedCaseInsensitiveContains(searchText)
        }
    }

    // 팀 선택 → UserDefaults에 저장
    func selectTeam(_ team: Team) {
        teamRepository.saveSelectedTeam(team)
    }
}
