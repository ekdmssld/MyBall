// WidgetAPIClient.swift
// 위젯 전용 API 클라이언트
// MLB: ESPN API / KBO: 공식 사이트 API 사용

import Foundation

enum WidgetAPIClient {
    // MARK: - ESPN (MLB)
    static func fetchESPNGames(date: Date) async -> [WidgetGame] {
        let dateString = date.widgetEspnDateString
        let urlString = WidgetConstants.scoreboardURL(league: "mlb", date: dateString)

        guard let url = URL(string: urlString) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(WidgetESPNResponse.self, from: data)
            return response.events?.compactMap { $0.toWidgetGame() } ?? []
        } catch {
            return []
        }
    }

    // MARK: - KBO 공식 사이트 API
    static func fetchKBOGames(year: Int, month: Int) async -> [WidgetGame] {
        let urlString = "https://www.koreabaseball.com/ws/Schedule.asmx/GetScheduleList"
        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("https://www.koreabaseball.com/Schedule/Schedule.aspx", forHTTPHeaderField: "Referer")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")

        let monthStr = String(format: "%02d", month)
        let body = "leId=1&srIdList=0%2C9%2C6&seasonId=\(year)&gameMonth=\(monthStr)&teamId="
        request.httpBody = body.data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return parseKBOResponse(data: data, year: year)
        } catch {
            return []
        }
    }

    // MARK: - 팀별 다음 경기 조회
    static func fetchUpcomingGames(team: WidgetTeam, days: Int = 7) async -> [WidgetGame] {
        var allGames: [WidgetGame] = []

        switch team.league {
        case .kbo:
            // KBO: 이번 달 + 다음 달 한 번에 조회 (2회 호출)
            let calendar = Calendar.current
            let now = Date()
            let year = calendar.component(.year, from: now)
            let month = calendar.component(.month, from: now)

            let thisMonthGames = await fetchKBOGames(year: year, month: month)
            allGames.append(contentsOf: thisMonthGames)

            // 다음 달도 조회 (월말에 다음 달 경기가 필요할 수 있음)
            let nextMonth = month == 12 ? 1 : month + 1
            let nextYear = month == 12 ? year + 1 : year
            let nextMonthGames = await fetchKBOGames(year: nextYear, month: nextMonth)
            allGames.append(contentsOf: nextMonthGames)

        case .mlb:
            // MLB: 날짜별 병렬 조회
            let calendar = Calendar.current
            await withTaskGroup(of: [WidgetGame].self) { group in
                for dayOffset in 0..<days {
                    guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else {
                        continue
                    }
                    group.addTask {
                        await fetchESPNGames(date: date)
                    }
                }
                for await games in group {
                    allGames.append(contentsOf: games)
                }
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

    // MARK: - KBO JSON 파싱
    private static let kboTeamNameToId: [String: String] = [
        "삼성": "kbo-samsung", "두산": "kbo-doosan", "LG": "kbo-lg", "KT": "kbo-kt",
        "SSG": "kbo-ssg", "키움": "kbo-kiwoom", "NC": "kbo-nc", "KIA": "kbo-kia",
        "롯데": "kbo-lotte", "한화": "kbo-hanwha",
    ]

    private static let kboTeamNameToAbbr: [String: String] = [
        "삼성": "SSL", "두산": "OB", "LG": "LG", "KT": "KT",
        "SSG": "SSG", "키움": "WO", "NC": "NC", "KIA": "HT",
        "롯데": "LT", "한화": "HH",
    ]

    private static func parseKBOResponse(data: Data, year: Int) -> [WidgetGame] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = json["rows"] as? [[String: Any]] else { return [] }

        var games: [WidgetGame] = []
        var currentDateStr = ""

        for rowData in rows {
            guard let cells = rowData["row"] as? [[String: Any]] else { continue }

            var cellIndex = 0
            if cells[0]["Class"] as? String == "day" {
                currentDateStr = stripHTML(cells[0]["Text"] as? String ?? "")
                cellIndex = 1
            }

            guard cellIndex < cells.count else { continue }
            let timeStr = stripHTML(cells[cellIndex]["Text"] as? String ?? "")
            cellIndex += 1

            guard cellIndex < cells.count else { continue }
            let playHTML = cells[cellIndex]["Text"] as? String ?? ""
            cellIndex += 1

            // gameId 추출
            var gameId = ""
            if cellIndex < cells.count {
                let relayHTML = cells[cellIndex]["Text"] as? String ?? ""
                if let range = relayHTML.range(of: "gameId=") {
                    let after = relayHTML[range.upperBound...]
                    if let end = after.range(of: "&") ?? after.range(of: "'") {
                        gameId = String(after[..<end.lowerBound])
                    }
                }
            }
            if gameId.isEmpty { gameId = "\(year)\(currentDateStr.prefix(5))" }

            // 경기장
            let venue = cells.count >= 2 ? stripHTML(cells[cells.count - 2]["Text"] as? String ?? "") : nil

            // 팀명 + 스코어 파싱
            guard let parsed = parsePlayHTML(playHTML) else { continue }

            // 날짜 파싱
            guard let gameDate = parseKBODate(dateStr: currentDateStr, timeStr: timeStr, year: year) else { continue }

            let statusName = parsed.awayScore != nil ? "STATUS_FINAL" : "STATUS_SCHEDULED"

            let game = WidgetGame(
                id: gameId,
                date: gameDate,
                homeTeamId: kboTeamNameToId[parsed.homeName] ?? parsed.homeName,
                homeTeamName: parsed.homeName,
                homeTeamAbbr: kboTeamNameToAbbr[parsed.homeName] ?? parsed.homeName,
                awayTeamId: kboTeamNameToId[parsed.awayName] ?? parsed.awayName,
                awayTeamName: parsed.awayName,
                awayTeamAbbr: kboTeamNameToAbbr[parsed.awayName] ?? parsed.awayName,
                venue: venue,
                homeScore: parsed.homeScore,
                awayScore: parsed.awayScore,
                statusName: statusName
            )
            games.append(game)
        }

        return games
    }

    private struct ParsedPlay {
        let awayName: String, homeName: String
        let awayScore: String?, homeScore: String?
    }

    private static func parsePlayHTML(_ html: String) -> ParsedPlay? {
        guard let emRange = html.range(of: "<em>"),
              let emEndRange = html.range(of: "</em>") else { return nil }

        let beforeEm = String(html[html.startIndex..<emRange.lowerBound])
        let afterEm = String(html[emEndRange.upperBound...])
        let emContent = String(html[emRange.upperBound..<emEndRange.lowerBound])

        let awayName = extractSpanTexts(from: beforeEm).first ?? ""
        let homeName = extractSpanTexts(from: afterEm).first ?? ""
        let emSpans = extractSpanTexts(from: emContent)

        if emSpans.count >= 3 && emSpans[0] != "vs" && emSpans[2] != "vs" {
            return ParsedPlay(awayName: awayName, homeName: homeName,
                              awayScore: emSpans[0], homeScore: emSpans[2])
        }
        return ParsedPlay(awayName: awayName, homeName: homeName, awayScore: nil, homeScore: nil)
    }

    private static func extractSpanTexts(from html: String) -> [String] {
        var results: [String] = []
        var remaining = html
        while let start = remaining.range(of: "<span") {
            let after = remaining[start.upperBound...]
            guard let close = after.range(of: ">") else { break }
            let contentStart = close.upperBound
            guard let end = remaining[contentStart...].range(of: "</span>") else { break }
            let text = String(remaining[contentStart..<end.lowerBound])
            if !text.isEmpty { results.append(text) }
            remaining = String(remaining[end.upperBound...])
        }
        return results
    }

    private static func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    private static func parseKBODate(dateStr: String, timeStr: String, year: Int) -> Date? {
        let cleaned = dateStr.replacingOccurrences(of: "\\(.*\\)", with: "", options: .regularExpression)
        let parts = cleaned.split(separator: ".")
        guard parts.count >= 2,
              let month = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let day = Int(parts[1].trimmingCharacters(in: .whitespaces)) else { return nil }

        let timeParts = timeStr.split(separator: ":")
        let hour = timeParts.count >= 1 ? Int(timeParts[0]) ?? 18 : 18
        let minute = timeParts.count >= 2 ? Int(timeParts[1]) ?? 0 : 0

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))
    }
}
