// NaverAPIClient.swift
// 네이버 스포츠 API 클라이언트 — 실시간 경기 현황 (루상 주자, 볼카운트, 선발투수)
// KBO 공식 API에는 실시간 데이터가 없어서 네이버 스포츠의 내부 API를 사용
// 비공식 API이므로 언제든 변경될 수 있음 → 모든 필드를 안전하게 옵셔널 처리

import Foundation

final class NaverAPIClient {
    static let shared = NaverAPIClient()

    private let session: URLSession
    private let baseURL = "https://api-gw.sports.naver.com"

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        session = URLSession(configuration: config)
    }

    // MARK: - 우리 앱 팀 ID → 네이버 팀 코드 매핑
    static let teamIdToNaverCode: [String: String] = [
        "kbo-samsung": "SS",
        "kbo-doosan": "OB",
        "kbo-lg": "LG",
        "kbo-kt": "KT",
        "kbo-ssg": "SK",
        "kbo-kiwoom": "WO",
        "kbo-nc": "NC",
        "kbo-kia": "HT",
        "kbo-lotte": "LT",
        "kbo-hanwha": "HH",
    ]

    // MARK: - 오늘 내 팀 경기 찾기
    // 오늘 KBO 전체 경기 목록에서 내 팀 경기를 찾아 반환 (없으면 nil)
    func fetchTodayGame(myTeamId: String, date: Date = Date()) async throws -> LiveGameInfo? {
        guard let naverCode = Self.teamIdToNaverCode[myTeamId] else { return nil }

        // 한국 시간 기준 오늘 날짜 (yyyy-MM-dd)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let dateString = formatter.string(from: date)

        let fields = "basic%2Cstadium%2CstatusCode%2CstatusInfo%2ChomeTeamScore%2CawayTeamScore"
        let urlString = "\(baseURL)/schedule/games?fields=\(fields)&upperCategoryId=kbaseball&categoryId=kbo&fromDate=\(dateString)&toDate=\(dateString)&size=50"

        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let (data, _) = try await session.data(from: url)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let games = result["games"] as? [[String: Any]] else {
            return nil
        }

        // 내 팀이 홈이거나 원정인 경기 찾기
        guard let gameJSON = games.first(where: { game in
            game["homeTeamCode"] as? String == naverCode
                || game["awayTeamCode"] as? String == naverCode
        }) else {
            return nil
        }

        return parseGameInfo(gameJSON)
    }

    // MARK: - 실시간 상세 상태 (문자중계)
    // 진행 중인 경기의 루상 주자, 볼카운트, 현재 투수/타자를 가져옴
    func fetchLiveDetail(gameId: String) async throws -> LiveGameDetail? {
        let urlString = "\(baseURL)/schedule/games/\(gameId)/relay?pageSize=5"
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let (data, _) = try await session.data(from: url)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let relayData = result["textRelayData"] as? [String: Any],
              let state = relayData["currentGameState"] as? [String: Any] else {
            return nil
        }

        // 문자열로 오는 숫자 값을 Int로 변환하는 헬퍼
        func intValue(_ key: String) -> Int {
            if let str = state[key] as? String { return Int(str) ?? 0 }
            return state[key] as? Int ?? 0
        }

        // 루상 주자: "0"이면 비어있음, 그 외 값이면 주자 있음
        func baseOccupied(_ key: String) -> Bool {
            if let str = state[key] as? String { return str != "0" && !str.isEmpty }
            if let num = state[key] as? Int { return num != 0 }
            return false
        }

        // 현재 투수/타자 이름: pcode(선수 ID)를 라인업에서 찾아서 이름으로 변환
        let pitcherId = (state["pitcher"] as? String) ?? String(describing: state["pitcher"] ?? "")
        let batterId = (state["batter"] as? String) ?? String(describing: state["batter"] ?? "")
        let names = findPlayerNames(relayData: relayData, ids: [pitcherId, batterId])

        return LiveGameDetail(
            balls: intValue("ball"),
            strikes: intValue("strike"),
            outs: intValue("out"),
            base1: baseOccupied("base1"),
            base2: baseOccupied("base2"),
            base3: baseOccupied("base3"),
            pitcherName: names[pitcherId],
            batterName: names[batterId],
            homeScore: intValue("homeScore"),
            awayScore: intValue("awayScore")
        )
    }

    // MARK: - 선발투수 정보 (경기 전 미리보기)
    func fetchStarters(gameId: String) async throws -> (home: StarterInfo?, away: StarterInfo?) {
        let urlString = "\(baseURL)/schedule/games/\(gameId)/preview"
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let (data, _) = try await session.data(from: url)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let preview = result["previewData"] as? [String: Any] else {
            return (nil, nil)
        }

        return (
            home: parseStarter(preview["homeStarter"] as? [String: Any]),
            away: parseStarter(preview["awayStarter"] as? [String: Any])
        )
    }

    // MARK: - 파싱 헬퍼

    private func parseGameInfo(_ json: [String: Any]) -> LiveGameInfo? {
        guard let gameId = json["gameId"] as? String else { return nil }

        // "2026-07-08T18:30:00" 형식의 시작 시각 파싱 (한국 시간)
        var gameDate: Date? = nil
        if let dateTimeStr = json["gameDateTime"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
            gameDate = formatter.date(from: dateTimeStr)
        }

        return LiveGameInfo(
            gameId: gameId,
            statusCode: json["statusCode"] as? String ?? "",
            statusInfo: json["statusInfo"] as? String ?? "",
            homeTeamCode: json["homeTeamCode"] as? String ?? "",
            homeTeamName: json["homeTeamName"] as? String ?? "",
            awayTeamCode: json["awayTeamCode"] as? String ?? "",
            awayTeamName: json["awayTeamName"] as? String ?? "",
            homeScore: json["homeTeamScore"] as? Int ?? 0,
            awayScore: json["awayTeamScore"] as? Int ?? 0,
            stadium: json["stadium"] as? String,
            gameDateTime: gameDate,
            canceled: json["cancel"] as? Bool ?? false
        )
    }

    // 라인업 데이터에서 선수 ID(pcode) → 이름 매핑 생성
    private func findPlayerNames(relayData: [String: Any], ids: [String]) -> [String: String] {
        var names: [String: String] = [:]

        for lineupKey in ["homeLineup", "awayLineup"] {
            guard let lineup = relayData[lineupKey] as? [String: Any] else { continue }

            for groupKey in ["batter", "pitcher"] {
                guard let players = lineup[groupKey] as? [[String: Any]] else { continue }

                for player in players {
                    guard let pcode = player["pcode"] as? String,
                          let name = player["name"] as? String,
                          ids.contains(pcode) else { continue }
                    names[pcode] = name
                }
            }
        }

        return names
    }

    private func parseStarter(_ json: [String: Any]?) -> StarterInfo? {
        guard let json = json else { return nil }

        // 이름은 playerInfo 안에 있음
        let playerInfo = json["playerInfo"] as? [String: Any]
        guard let name = playerInfo?["name"] as? String else { return nil }

        // ERA는 currentSeasonStats 안에 있음
        let stats = json["currentSeasonStats"] as? [String: Any]
        let era = stats?["era"] as? String ?? (stats?["era"] as? Double).map { String(format: "%.2f", $0) }

        return StarterInfo(name: name, era: era)
    }
}
