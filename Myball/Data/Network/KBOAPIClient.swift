// KBOAPIClient.swift
// KBO 공식 사이트(koreabaseball.com)에서 경기 일정을 가져오는 클라이언트
// ESPN KBO API가 동작하지 않아 공식 사이트의 내부 API를 사용

import Foundation

final class KBOAPIClient {
    static let shared = KBOAPIClient()

    private let session: URLSession
    private let scheduleURL = "https://www.koreabaseball.com/ws/Schedule.asmx/GetScheduleList"

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)
    }

    // MARK: - KBO 팀 이름 → 팀 ID 매핑
    // KBO 사이트는 한글 팀명을 사용 (삼성, 두산, LG 등)
    private static let teamNameToId: [String: String] = [
        "삼성": "kbo-samsung",
        "두산": "kbo-doosan",
        "LG": "kbo-lg",
        "KT": "kbo-kt",
        "SSG": "kbo-ssg",
        "키움": "kbo-kiwoom",
        "NC": "kbo-nc",
        "KIA": "kbo-kia",
        "롯데": "kbo-lotte",
        "한화": "kbo-hanwha",
    ]

    // KBO 팀 이름 → 약칭 매핑 (캘린더 표시용)
    private static let teamNameToAbbr: [String: String] = [
        "삼성": "SSL", "두산": "OB", "LG": "LG", "KT": "KT",
        "SSG": "SSG", "키움": "WO", "NC": "NC", "KIA": "HT",
        "롯데": "LT", "한화": "HH",
    ]

    // MARK: - 월별 경기 일정 조회
    // KBO API는 한 번의 호출로 월별 전체 일정을 반환 (ESPN보다 효율적)
    func fetchMonthSchedule(year: Int, month: Int) async throws -> [Game] {
        guard let url = URL(string: scheduleURL) else {
            throw APIError.invalidURL
        }

        // POST 요청 구성 (form-encoded)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("https://www.koreabaseball.com/Schedule/Schedule.aspx", forHTTPHeaderField: "Referer")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")

        let monthStr = String(format: "%02d", month)
        let body = "leId=1&srIdList=0%2C9%2C6&seasonId=\(year)&gameMonth=\(monthStr)&teamId="
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(httpResponse.statusCode)
        }

        return parseScheduleResponse(data: data, year: year)
    }

    // MARK: - JSON 파싱
    // KBO API 응답 → Game 배열로 변환
    private func parseScheduleResponse(data: Data, year: Int) -> [Game] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = json["rows"] as? [[String: Any]] else {
            return []
        }

        var games: [Game] = []
        var currentDateStr = ""  // 현재 처리 중인 날짜 (RowSpan 그룹)

        for rowData in rows {
            guard let cells = rowData["row"] as? [[String: Any]] else { continue }

            // RowSpan이 있는 셀 = 새로운 날짜 그룹 시작
            // 날짜 셀이 있으면 업데이트, 없으면 이전 날짜 유지
            var cellIndex = 0
            let firstCell = cells[0]
            if firstCell["Class"] as? String == "day" {
                currentDateStr = stripHTML(firstCell["Text"] as? String ?? "")
                cellIndex = 1  // 다음 셀부터 시간
            }

            // 셀 인덱스 조정 (날짜 셀 유무에 따라)
            guard cellIndex < cells.count else { continue }

            // 시간 파싱 — "<b>18:30</b>" → "18:30"
            let timeStr = stripHTML(cells[cellIndex]["Text"] as? String ?? "")
            cellIndex += 1

            guard cellIndex < cells.count else { continue }

            // 경기 정보 파싱 — HTML에서 팀명과 스코어 추출
            let playHTML = cells[cellIndex]["Text"] as? String ?? ""
            guard let gameInfo = parsePlayCell(playHTML) else { continue }
            cellIndex += 1

            // gameId 추출 (relay 셀에서)
            var gameId = ""
            if cellIndex < cells.count {
                let relayHTML = cells[cellIndex]["Text"] as? String ?? ""
                gameId = extractGameId(from: relayHTML) ?? "\(year)\(currentDateStr.prefix(5))\(gameInfo.awayName)\(gameInfo.homeName)"
            }

            // 경기장 파싱 (뒤에서 2번째 셀)
            let venue = cells.count >= 2 ? stripHTML(cells[cells.count - 2]["Text"] as? String ?? "") : nil

            // 날짜+시간 → Date 객체
            guard let gameDate = parseKBODate(dateStr: currentDateStr, timeStr: timeStr, year: year) else {
                continue
            }

            // 경기 상태 결정
            let status: GameStatus
            if gameInfo.awayScore != nil {
                status = .final_
            } else if gameDate > Date() {
                status = .scheduled
            } else {
                status = .scheduled
            }

            // Game 객체 생성
            let awayTeamId = Self.teamNameToId[gameInfo.awayName] ?? gameInfo.awayName
            let homeTeamId = Self.teamNameToId[gameInfo.homeName] ?? gameInfo.homeName
            let awayAbbr = Self.teamNameToAbbr[gameInfo.awayName] ?? gameInfo.awayName
            let homeAbbr = Self.teamNameToAbbr[gameInfo.homeName] ?? gameInfo.homeName

            let game = Game(
                id: gameId,
                date: gameDate,
                homeTeam: GameTeam(
                    teamId: homeTeamId,
                    name: gameInfo.homeName,
                    abbreviation: homeAbbr,
                    logoURL: nil,
                    score: gameInfo.homeScore,
                    isWinner: gameInfo.homeScore != nil && gameInfo.awayScore != nil
                        && (Int(gameInfo.homeScore!) ?? 0) > (Int(gameInfo.awayScore!) ?? 0)
                ),
                awayTeam: GameTeam(
                    teamId: awayTeamId,
                    name: gameInfo.awayName,
                    abbreviation: awayAbbr,
                    logoURL: nil,
                    score: gameInfo.awayScore,
                    isWinner: gameInfo.awayScore != nil && gameInfo.homeScore != nil
                        && (Int(gameInfo.awayScore!) ?? 0) > (Int(gameInfo.homeScore!) ?? 0)
                ),
                venue: venue,
                status: status,
                league: .kbo
            )

            games.append(game)
        }

        return games
    }

    // MARK: - Play 셀 HTML 파싱
    // 예정: <span>키움</span><em><span>vs</span></em><span>두산</span>
    // 종료: <span>두산</span><em><span class="lose">0</span><span>vs</span><span class="win">1</span></em><span>키움</span>
    private struct GameInfo {
        let awayName: String
        let homeName: String
        let awayScore: String?
        let homeScore: String?
    }

    private func parsePlayCell(_ html: String) -> GameInfo? {
        // <span>으로 시작하는 팀명들과 스코어를 추출
        // 패턴: <span>Away</span><em>..scores..vs..scores..</em><span>Home</span>

        // 팀명 추출 — <em> 태그 바깥의 <span> 내용
        let spanPattern = "<span>([^<]+)</span>"
        let emContent: String
        let outerSpans: [String]

        // <em>...</em> 안의 내용과 바깥의 span을 분리
        if let emRange = html.range(of: "<em>"),
           let emEndRange = html.range(of: "</em>") {
            let beforeEm = String(html[html.startIndex..<emRange.lowerBound])
            let afterEm = String(html[emEndRange.upperBound...])
            emContent = String(html[emRange.upperBound..<emEndRange.lowerBound])

            // 바깥 span에서 팀명 추출
            let awayName = extractSpanTexts(from: beforeEm).first ?? ""
            let homeName = extractSpanTexts(from: afterEm).first ?? ""

            // <em> 안에서 스코어 추출
            let emSpans = extractSpanTexts(from: emContent)
            // emSpans 가능한 형태:
            // 예정: ["vs"]
            // 종료: ["0", "vs", "1"] 또는 숫자만 포함

            if emSpans.count >= 3 {
                // 스코어 있음: [awayScore, "vs", homeScore]
                let awayScore = emSpans[0]
                let homeScore = emSpans[2]
                if awayScore != "vs" && homeScore != "vs" {
                    return GameInfo(awayName: awayName, homeName: homeName,
                                   awayScore: awayScore, homeScore: homeScore)
                }
            }

            // 스코어 없음 (예정된 경기)
            return GameInfo(awayName: awayName, homeName: homeName,
                           awayScore: nil, homeScore: nil)
        }

        return nil
    }

    // HTML에서 <span>내용</span> 추출
    private func extractSpanTexts(from html: String) -> [String] {
        var results: [String] = []
        var remaining = html

        while let startRange = remaining.range(of: "<span") {
            // > 찾기 (class 속성이 있을 수 있으므로)
            let afterStart = remaining[startRange.upperBound...]
            guard let closeTagRange = afterStart.range(of: ">") else { break }
            let contentStart = closeTagRange.upperBound

            guard let endRange = remaining[contentStart...].range(of: "</span>") else { break }
            let text = String(remaining[contentStart..<endRange.lowerBound])
            if !text.isEmpty {
                results.append(text)
            }
            remaining = String(remaining[endRange.upperBound...])
        }

        return results
    }

    // MARK: - 유틸리티

    // HTML 태그 제거
    private func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    // relay 셀에서 gameId 추출
    // "...gameId=20250601OBWO0..." → "20250601OBWO0"
    private func extractGameId(from html: String) -> String? {
        guard let range = html.range(of: "gameId=") else { return nil }
        let afterId = html[range.upperBound...]
        if let endRange = afterId.range(of: "&") {
            return String(afterId[..<endRange.lowerBound])
        }
        if let endRange = afterId.range(of: "'") {
            return String(afterId[..<endRange.lowerBound])
        }
        return nil
    }

    // KBO 날짜 문자열 → Date
    // "04.01(화)" + "18:30" + year=2025 → Date
    private func parseKBODate(dateStr: String, timeStr: String, year: Int) -> Date? {
        // "04.01(화)" → month=4, day=1
        let cleaned = dateStr.replacingOccurrences(of: "\\(.*\\)", with: "", options: .regularExpression)
        let parts = cleaned.split(separator: ".")
        guard parts.count >= 2,
              let month = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let day = Int(parts[1].trimmingCharacters(in: .whitespaces)) else {
            return nil
        }

        // "18:30" → hour=18, minute=30
        let timeParts = timeStr.split(separator: ":")
        let hour = timeParts.count >= 1 ? Int(timeParts[0]) ?? 18 : 18
        let minute = timeParts.count >= 2 ? Int(timeParts[1]) ?? 0 : 0

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!

        return calendar.date(from: DateComponents(
            year: year, month: month, day: day,
            hour: hour, minute: minute
        ))
    }
}
