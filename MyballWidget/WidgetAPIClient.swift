// WidgetAPIClient.swift
// 위젯 전용 API 클라이언트 — 가볍게 ESPN 스코어보드를 조회
// 위젯은 메모리/시간 제한이 있으므로 최소한의 데이터만 가져옴

import Foundation

enum WidgetAPIClient {
    // 특정 날짜의 경기를 가져옴
    static func fetchGames(league: WidgetLeague, date: Date) async -> [WidgetGame] {
        let dateString = date.widgetEspnDateString
        let urlString = WidgetConstants.scoreboardURL(league: league.espnPath, date: dateString)

        guard let url = URL(string: urlString) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(WidgetESPNResponse.self, from: data)
            return response.events?.compactMap { $0.toWidgetGame() } ?? []
        } catch {
            return []
        }
    }

    // 오늘부터 7일간의 내 팀 경기를 가져옴
    // 위젯에서 "다음 경기"와 "이번 주 경기"를 보여주기 위해 사용
    static func fetchUpcomingGames(team: WidgetTeam, days: Int = 7) async -> [WidgetGame] {
        // KBO API는 동작하지 않음
        if team.league == .kbo { return [] }

        var allGames: [WidgetGame] = []
        let calendar = Calendar.current

        // 병렬로 여러 날짜 조회 (위젯은 빠르게 데이터를 가져와야 함)
        await withTaskGroup(of: [WidgetGame].self) { group in
            for dayOffset in 0..<days {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else {
                    continue
                }
                group.addTask {
                    await fetchGames(league: team.league, date: date)
                }
            }

            for await games in group {
                allGames.append(contentsOf: games)
            }
        }

        // 내 팀 경기만 필터링
        let myGames = allGames.filter { game in
            game.homeTeamId == team.id || game.awayTeamId == team.id
        }

        // 중복 제거 + 날짜순 정렬
        var seen = Set<String>()
        return myGames
            .filter { game in
                if seen.contains(game.id) { return false }
                seen.insert(game.id)
                return true
            }
            .sorted { $0.date < $1.date }
    }
}
