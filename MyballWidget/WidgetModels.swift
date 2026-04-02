// WidgetModels.swift
// 위젯 전용 모델 — 위젯은 별도 프로세스이므로 메인 앱 코드를 직접 사용할 수 없음
// 필요한 모델만 최소한으로 복제

import SwiftUI

// MARK: - 상수
enum WidgetConstants {
    static let appGroupID = "group.com.myball.shared"
    static let selectedTeamIDKey = "selectedTeamID"
    static let selectedLeagueKey = "selectedLeague"
    static let espnBaseURL = "https://site.api.espn.com/apis/site/v2/sports/baseball"

    static func scoreboardURL(league: String, date: String) -> String {
        "\(espnBaseURL)/\(league)/scoreboard?dates=\(date)"
    }
}

// MARK: - 리그
enum WidgetLeague: String, Codable {
    case kbo, mlb
    var espnPath: String { rawValue }
    var displayName: String {
        switch self {
        case .kbo: return "KBO"
        case .mlb: return "MLB"
        }
    }
}

// MARK: - 팀 (위젯용 최소 모델)
struct WidgetTeam: Codable {
    let id: String
    let name: String
    let shortName: String
    let abbreviation: String
    let league: WidgetLeague
    let colorHex: String
    let altColorHex: String
    let logoURL: String?

    var color: Color { Color(hex: colorHex) }
    var altColor: Color { Color(hex: altColorHex) }

    // UserDefaults에서 팀 ID를 읽어서 팀 데이터 반환
    static func find(by id: String) -> WidgetTeam? {
        allTeams.first(where: { $0.id == id })
    }

    // 모든 팀 (KBO + MLB)
    static let allTeams: [WidgetTeam] = kboTeams + mlbTeams

    // KBO 10개 팀
    static let kboTeams: [WidgetTeam] = [
        WidgetTeam(id: "kbo-samsung", name: "삼성 라이온즈", shortName: "삼성", abbreviation: "SSL", league: .kbo, colorHex: "074CA1", altColorHex: "FFFFFF", logoURL: nil),
        WidgetTeam(id: "kbo-doosan", name: "두산 베어스", shortName: "두산", abbreviation: "OB", league: .kbo, colorHex: "131230", altColorHex: "ED1C24", logoURL: nil),
        WidgetTeam(id: "kbo-lg", name: "LG 트윈스", shortName: "LG", abbreviation: "LG", league: .kbo, colorHex: "C30452", altColorHex: "000000", logoURL: nil),
        WidgetTeam(id: "kbo-kt", name: "KT 위즈", shortName: "KT", abbreviation: "KT", league: .kbo, colorHex: "000000", altColorHex: "ED1C24", logoURL: nil),
        WidgetTeam(id: "kbo-ssg", name: "SSG 랜더스", shortName: "SSG", abbreviation: "SSG", league: .kbo, colorHex: "CE0E2D", altColorHex: "F5A200", logoURL: nil),
        WidgetTeam(id: "kbo-kiwoom", name: "키움 히어로즈", shortName: "키움", abbreviation: "WO", league: .kbo, colorHex: "820024", altColorHex: "000000", logoURL: nil),
        WidgetTeam(id: "kbo-nc", name: "NC 다이노스", shortName: "NC", abbreviation: "NC", league: .kbo, colorHex: "1D467D", altColorHex: "C5A052", logoURL: nil),
        WidgetTeam(id: "kbo-kia", name: "KIA 타이거즈", shortName: "KIA", abbreviation: "HT", league: .kbo, colorHex: "EA0029", altColorHex: "000000", logoURL: nil),
        WidgetTeam(id: "kbo-lotte", name: "롯데 자이언츠", shortName: "롯데", abbreviation: "LT", league: .kbo, colorHex: "041E42", altColorHex: "D00F31", logoURL: nil),
        WidgetTeam(id: "kbo-hanwha", name: "한화 이글스", shortName: "한화", abbreviation: "HH", league: .kbo, colorHex: "FF6600", altColorHex: "000000", logoURL: nil),
    ]

    // MLB 30개 팀
    static let mlbTeams: [WidgetTeam] = [
        WidgetTeam(id: "1", name: "Baltimore Orioles", shortName: "Orioles", abbreviation: "BAL", league: .mlb, colorHex: "df4601", altColorHex: "000000", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/bal.png"),
        WidgetTeam(id: "2", name: "Boston Red Sox", shortName: "Red Sox", abbreviation: "BOS", league: .mlb, colorHex: "0d2b56", altColorHex: "bd3039", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/bos.png"),
        WidgetTeam(id: "10", name: "New York Yankees", shortName: "Yankees", abbreviation: "NYY", league: .mlb, colorHex: "132448", altColorHex: "c4ced4", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/nyy.png"),
        WidgetTeam(id: "30", name: "Tampa Bay Rays", shortName: "Rays", abbreviation: "TB", league: .mlb, colorHex: "092c5c", altColorHex: "8fbce6", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/tb.png"),
        WidgetTeam(id: "14", name: "Toronto Blue Jays", shortName: "Blue Jays", abbreviation: "TOR", league: .mlb, colorHex: "134a8e", altColorHex: "e8291c", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/tor.png"),
        WidgetTeam(id: "4", name: "Chicago White Sox", shortName: "White Sox", abbreviation: "CHW", league: .mlb, colorHex: "000000", altColorHex: "c4ced4", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/chw.png"),
        WidgetTeam(id: "5", name: "Cleveland Guardians", shortName: "Guardians", abbreviation: "CLE", league: .mlb, colorHex: "002b5c", altColorHex: "e31937", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/cle.png"),
        WidgetTeam(id: "6", name: "Detroit Tigers", shortName: "Tigers", abbreviation: "DET", league: .mlb, colorHex: "0a2240", altColorHex: "ff4713", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/det.png"),
        WidgetTeam(id: "7", name: "Kansas City Royals", shortName: "Royals", abbreviation: "KC", league: .mlb, colorHex: "004687", altColorHex: "7ab2dd", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/kc.png"),
        WidgetTeam(id: "9", name: "Minnesota Twins", shortName: "Twins", abbreviation: "MIN", league: .mlb, colorHex: "031f40", altColorHex: "e20e32", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/min.png"),
        WidgetTeam(id: "18", name: "Houston Astros", shortName: "Astros", abbreviation: "HOU", league: .mlb, colorHex: "002d62", altColorHex: "eb6e1f", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/hou.png"),
        WidgetTeam(id: "3", name: "Los Angeles Angels", shortName: "Angels", abbreviation: "LAA", league: .mlb, colorHex: "ba0021", altColorHex: "c4ced4", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/laa.png"),
        WidgetTeam(id: "11", name: "Athletics", shortName: "Athletics", abbreviation: "ATH", league: .mlb, colorHex: "003831", altColorHex: "efb21e", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/oak.png"),
        WidgetTeam(id: "12", name: "Seattle Mariners", shortName: "Mariners", abbreviation: "SEA", league: .mlb, colorHex: "0c2c56", altColorHex: "005c5c", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/sea.png"),
        WidgetTeam(id: "13", name: "Texas Rangers", shortName: "Rangers", abbreviation: "TEX", league: .mlb, colorHex: "003278", altColorHex: "c0111f", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/tex.png"),
        WidgetTeam(id: "15", name: "Atlanta Braves", shortName: "Braves", abbreviation: "ATL", league: .mlb, colorHex: "0c2340", altColorHex: "ba0c2f", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/atl.png"),
        WidgetTeam(id: "28", name: "Miami Marlins", shortName: "Marlins", abbreviation: "MIA", league: .mlb, colorHex: "00a3e0", altColorHex: "000000", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/mia.png"),
        WidgetTeam(id: "21", name: "New York Mets", shortName: "Mets", abbreviation: "NYM", league: .mlb, colorHex: "002d72", altColorHex: "ff5910", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/nym.png"),
        WidgetTeam(id: "22", name: "Philadelphia Phillies", shortName: "Phillies", abbreviation: "PHI", league: .mlb, colorHex: "e81828", altColorHex: "003278", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/phi.png"),
        WidgetTeam(id: "20", name: "Washington Nationals", shortName: "Nationals", abbreviation: "WSH", league: .mlb, colorHex: "ab0003", altColorHex: "14225a", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/wsh.png"),
        WidgetTeam(id: "16", name: "Chicago Cubs", shortName: "Cubs", abbreviation: "CHC", league: .mlb, colorHex: "0e3386", altColorHex: "cc3433", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/chc.png"),
        WidgetTeam(id: "17", name: "Cincinnati Reds", shortName: "Reds", abbreviation: "CIN", league: .mlb, colorHex: "c6011f", altColorHex: "ffffff", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/cin.png"),
        WidgetTeam(id: "8", name: "Milwaukee Brewers", shortName: "Brewers", abbreviation: "MIL", league: .mlb, colorHex: "13294b", altColorHex: "ffc72c", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/mil.png"),
        WidgetTeam(id: "23", name: "Pittsburgh Pirates", shortName: "Pirates", abbreviation: "PIT", league: .mlb, colorHex: "000000", altColorHex: "fdb827", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/pit.png"),
        WidgetTeam(id: "24", name: "St. Louis Cardinals", shortName: "Cardinals", abbreviation: "STL", league: .mlb, colorHex: "c41e3a", altColorHex: "0c2340", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/stl.png"),
        WidgetTeam(id: "29", name: "Arizona Diamondbacks", shortName: "D-backs", abbreviation: "ARI", league: .mlb, colorHex: "aa182c", altColorHex: "000000", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/ari.png"),
        WidgetTeam(id: "27", name: "Colorado Rockies", shortName: "Rockies", abbreviation: "COL", league: .mlb, colorHex: "33006f", altColorHex: "000000", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/col.png"),
        WidgetTeam(id: "19", name: "Los Angeles Dodgers", shortName: "Dodgers", abbreviation: "LAD", league: .mlb, colorHex: "005a9c", altColorHex: "ffffff", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/lad.png"),
        WidgetTeam(id: "25", name: "San Diego Padres", shortName: "Padres", abbreviation: "SD", league: .mlb, colorHex: "2f241d", altColorHex: "ffc425", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/sd.png"),
        WidgetTeam(id: "26", name: "San Francisco Giants", shortName: "Giants", abbreviation: "SF", league: .mlb, colorHex: "fd5a1e", altColorHex: "000000", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/sf.png"),
    ]
}

// MARK: - 위젯용 경기 모델
struct WidgetGame: Codable {
    let id: String
    let date: Date
    let homeTeamId: String
    let homeTeamName: String
    let homeTeamAbbr: String
    let awayTeamId: String
    let awayTeamName: String
    let awayTeamAbbr: String
    let venue: String?
    let homeScore: String?
    let awayScore: String?
    let statusName: String // "STATUS_SCHEDULED", "STATUS_FINAL" 등

    // 내 팀이 홈인지
    func isHome(teamId: String) -> Bool {
        homeTeamId == teamId
    }

    // 상대팀 약칭
    func opponentAbbr(myTeamId: String) -> String {
        homeTeamId == myTeamId ? awayTeamAbbr : homeTeamAbbr
    }

    // 상대팀 이름
    func opponentName(myTeamId: String) -> String {
        homeTeamId == myTeamId ? awayTeamName : homeTeamName
    }

    // 경기 상태 텍스트
    var statusText: String {
        switch statusName {
        case "STATUS_SCHEDULED", "STATUS_WARMUP": return "예정"
        case "STATUS_IN_PROGRESS", "STATUS_RAIN_DELAY", "STATUS_DELAYED": return "진행 중"
        case "STATUS_FINAL": return "종료"
        case "STATUS_POSTPONED": return "연기"
        case "STATUS_CANCELED": return "취소"
        default: return "예정"
        }
    }

    var isScheduled: Bool {
        statusName == "STATUS_SCHEDULED" || statusName == "STATUS_WARMUP"
    }

    var isFinal: Bool {
        statusName == "STATUS_FINAL"
    }

    // 스코어 텍스트
    var scoreText: String? {
        guard let h = homeScore, let a = awayScore else { return nil }
        return "\(a) - \(h)"
    }

    // 한국 시간 표시
    var koreanTimeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }

    // 날짜 표시 (간략)
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d (E)"
        return formatter.string(from: date)
    }
}

// MARK: - ESPN DTO (위젯용 최소 버전)
struct WidgetESPNResponse: Codable {
    let events: [WidgetESPNEvent]?
}

struct WidgetESPNEvent: Codable {
    let id: String
    let date: String
    let competitions: [WidgetESPNCompetition]?
}

struct WidgetESPNCompetition: Codable {
    let venue: WidgetESPNVenue?
    let competitors: [WidgetESPNCompetitor]?
    let status: WidgetESPNStatus?
}

struct WidgetESPNVenue: Codable {
    let fullName: String?
}

struct WidgetESPNCompetitor: Codable {
    let homeAway: String?
    let team: WidgetESPNTeamInfo?
    let score: String?
}

struct WidgetESPNTeamInfo: Codable {
    let id: String?
    let abbreviation: String?
    let displayName: String?
}

struct WidgetESPNStatus: Codable {
    let type: WidgetESPNStatusType?
}

struct WidgetESPNStatusType: Codable {
    let name: String?
}

// MARK: - ESPN → WidgetGame 변환
extension WidgetESPNEvent {
    func toWidgetGame() -> WidgetGame? {
        guard let competition = competitions?.first,
              let competitors = competition.competitors,
              competitors.count >= 2 else { return nil }

        let home = competitors.first(where: { $0.homeAway == "home" })
        let away = competitors.first(where: { $0.homeAway == "away" })

        guard let home = home, let away = away else { return nil }

        // ISO 8601 날짜 파싱
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let gameDate = dateFormatter.date(from: date)
            ?? ISO8601DateFormatter().date(from: date)
            ?? Date()

        return WidgetGame(
            id: id,
            date: gameDate,
            homeTeamId: home.team?.id ?? "",
            homeTeamName: home.team?.displayName ?? "Unknown",
            homeTeamAbbr: home.team?.abbreviation ?? "???",
            awayTeamId: away.team?.id ?? "",
            awayTeamName: away.team?.displayName ?? "Unknown",
            awayTeamAbbr: away.team?.abbreviation ?? "???",
            venue: competition.venue?.fullName,
            homeScore: home.score,
            awayScore: away.score,
            statusName: competition.status?.type?.name ?? "STATUS_SCHEDULED"
        )
    }
}

// MARK: - Color HEX 변환
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Date 확장 (위젯용)
extension Date {
    // ESPN API용 날짜 포맷 "YYYYMMDD"
    var widgetEspnDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return formatter.string(from: self)
    }
}
