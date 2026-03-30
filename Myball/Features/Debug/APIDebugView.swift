// APIDebugView.swift
// ESPN API를 직접 테스트해볼 수 있는 디버그 화면
// #if DEBUG로 감싸서 릴리즈 빌드에서는 제외됨

#if DEBUG
import SwiftUI

struct APIDebugView: View {
    // @State: 이 화면의 로컬 상태 (Flutter의 setState와 비슷)
    @State private var selectedLeague: League = .mlb
    @State private var responseText: String = "API를 테스트해보세요"
    @State private var isLoading = false
    @State private var testDate = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.large) {
                // 리그 선택 (세그먼트 컨트롤)
                Picker("리그", selection: $selectedLeague) {
                    ForEach(League.allCases) { league in
                        Text(league.displayName).tag(league)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // 날짜 선택
                DatePicker("날짜", selection: $testDate, displayedComponents: .date)
                    .padding(.horizontal)

                // 테스트 버튼들
                HStack(spacing: Theme.Spacing.medium) {
                    Button("스코어보드 조회") {
                        Task { await fetchScoreboard() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("팀 목록 조회") {
                        Task { await fetchTeams() }
                    }
                    .buttonStyle(.bordered)
                }

                // 결과 표시
                if isLoading {
                    ProgressView("로딩 중...")
                } else {
                    ScrollView {
                        Text(responseText)
                            .font(.system(size: 11, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer()
            }
            .navigationTitle("API 디버그")
        }
    }

    // 스코어보드 API 테스트
    private func fetchScoreboard() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let urlString = Constants.scoreboardURL(
                league: selectedLeague.espnPath,
                date: testDate.espnDateString
            )
            let raw = try await APIClient.shared.fetchRawJSON(from: urlString)

            // 파싱된 결과도 함께 표시
            let games = try await APIClient.shared.fetchScoreboard(league: selectedLeague, date: testDate)
            let summary = games.map { game in
                "\(game.awayTeam.abbreviation) @ \(game.homeTeam.abbreviation) — \(game.status.displayText) \(game.scoreText ?? "")"
            }.joined(separator: "\n")

            responseText = "=== 파싱 결과 (\(games.count)경기) ===\n\(summary)\n\n=== Raw JSON ===\n\(raw)"
        } catch {
            responseText = "에러: \(error.localizedDescription)"
        }
    }

    // 팀 목록 API 테스트
    private func fetchTeams() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let teams = try await APIClient.shared.fetchTeams(league: selectedLeague)
            let summary = teams.map { team in
                "ID: \(team.id ?? "?") | \(team.abbreviation ?? "?") | \(team.displayName ?? "?")"
            }.joined(separator: "\n")

            responseText = "=== \(selectedLeague.displayName) 팀 목록 (\(teams.count)팀) ===\n\(summary)"
        } catch {
            responseText = "에러: \(error.localizedDescription)"
        }
    }
}

#Preview {
    APIDebugView()
}
#endif
