// WidgetModels.swift
// 위젯 전용 모델 — 위젯은 별도 프로세스이므로 메인 앱 코드를 직접 사용할 수 없음
// 필요한 모델만 최소한으로 복제 (KBO 전용)

import SwiftUI

// MARK: - 상수
enum WidgetConstants {
    static let appGroupID = "group.com.myball.shared"
    static let selectedTeamIDKey = "selectedTeamID"
    static let selectedLeagueKey = "selectedLeague"
}

// MARK: - 리그 (KBO 전용)
enum WidgetLeague: String, Codable {
    case kbo
    var displayName: String { "KBO" }
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
        kboTeams.first(where: { $0.id == id })
    }

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
