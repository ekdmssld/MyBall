// Team.swift
// 야구팀 모델 + KBO 10개 팀 / MLB 30개 팀 하드코딩 데이터

import SwiftUI

// struct는 Flutter의 class와 비슷하지만, 값 타입(value type)임
// Identifiable: SwiftUI에서 목록 표시에 필요
// Codable: JSON 변환 + UserDefaults 저장에 필요
// Equatable: == 비교에 필요
struct Team: Identifiable, Codable, Equatable, Hashable {
    let id: String           // ESPN 팀 ID
    let name: String         // 팀 전체 이름 (예: "삼성 라이온즈")
    let shortName: String    // 짧은 이름 (예: "삼성")
    let abbreviation: String // 약칭 (예: "SSL")
    let league: League
    let colorHex: String     // 팀 주 색상 (HEX, # 없이)
    let altColorHex: String  // 팀 보조 색상
    let logoURL: String?     // ESPN 로고 URL (KBO는 없을 수 있음)

    // HEX 문자열 → SwiftUI Color 변환
    // computed property: Flutter의 getter와 비슷
    var color: Color {
        Color(hex: colorHex)
    }

    var altColor: Color {
        Color(hex: altColorHex)
    }
}

// MARK: - Color HEX 변환 extension
extension Color {
    // "#FF5733" 또는 "FF5733" 형식의 HEX 문자열을 Color로 변환
    init(hex: String) {
        // "#" 제거
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        // 6자리 HEX를 RGB로 분리
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - KBO 10개 팀 데이터
extension Team {
    // static: 인스턴스 없이 Team.kboTeams로 접근 가능
    static let kboTeams: [Team] = [
        Team(
            id: "kbo-samsung", name: "삼성 라이온즈", shortName: "삼성",
            abbreviation: "SSL", league: .kbo,
            colorHex: "074CA1", altColorHex: "FFFFFF", logoURL: nil
        ),
        Team(
            id: "kbo-doosan", name: "두산 베어스", shortName: "두산",
            abbreviation: "OB", league: .kbo,
            colorHex: "131230", altColorHex: "ED1C24", logoURL: nil
        ),
        Team(
            id: "kbo-lg", name: "LG 트윈스", shortName: "LG",
            abbreviation: "LG", league: .kbo,
            colorHex: "C30452", altColorHex: "000000", logoURL: nil
        ),
        Team(
            id: "kbo-kt", name: "KT 위즈", shortName: "KT",
            abbreviation: "KT", league: .kbo,
            colorHex: "000000", altColorHex: "ED1C24", logoURL: nil
        ),
        Team(
            id: "kbo-ssg", name: "SSG 랜더스", shortName: "SSG",
            abbreviation: "SSG", league: .kbo,
            colorHex: "CE0E2D", altColorHex: "F5A200", logoURL: nil
        ),
        Team(
            id: "kbo-kiwoom", name: "키움 히어로즈", shortName: "키움",
            abbreviation: "WO", league: .kbo,
            colorHex: "820024", altColorHex: "000000", logoURL: nil
        ),
        Team(
            id: "kbo-nc", name: "NC 다이노스", shortName: "NC",
            abbreviation: "NC", league: .kbo,
            colorHex: "1D467D", altColorHex: "C5A052", logoURL: nil
        ),
        Team(
            id: "kbo-kia", name: "KIA 타이거즈", shortName: "KIA",
            abbreviation: "HT", league: .kbo,
            colorHex: "EA0029", altColorHex: "000000", logoURL: nil
        ),
        Team(
            id: "kbo-lotte", name: "롯데 자이언츠", shortName: "롯데",
            abbreviation: "LT", league: .kbo,
            colorHex: "041E42", altColorHex: "D00F31", logoURL: nil
        ),
        Team(
            id: "kbo-hanwha", name: "한화 이글스", shortName: "한화",
            abbreviation: "HH", league: .kbo,
            colorHex: "FF6600", altColorHex: "000000", logoURL: nil
        ),
    ]

    // MARK: - MLB 30개 팀 데이터
    static let mlbTeams: [Team] = [
        // AL East
        Team(id: "1", name: "Baltimore Orioles", shortName: "Orioles",
             abbreviation: "BAL", league: .mlb,
             colorHex: "df4601", altColorHex: "000000",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/bal.png"),
        Team(id: "2", name: "Boston Red Sox", shortName: "Red Sox",
             abbreviation: "BOS", league: .mlb,
             colorHex: "0d2b56", altColorHex: "bd3039",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/bos.png"),
        Team(id: "10", name: "New York Yankees", shortName: "Yankees",
             abbreviation: "NYY", league: .mlb,
             colorHex: "132448", altColorHex: "c4ced4",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/nyy.png"),
        Team(id: "30", name: "Tampa Bay Rays", shortName: "Rays",
             abbreviation: "TB", league: .mlb,
             colorHex: "092c5c", altColorHex: "8fbce6",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/tb.png"),
        Team(id: "14", name: "Toronto Blue Jays", shortName: "Blue Jays",
             abbreviation: "TOR", league: .mlb,
             colorHex: "134a8e", altColorHex: "e8291c",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/tor.png"),
        // AL Central
        Team(id: "4", name: "Chicago White Sox", shortName: "White Sox",
             abbreviation: "CHW", league: .mlb,
             colorHex: "000000", altColorHex: "c4ced4",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/chw.png"),
        Team(id: "5", name: "Cleveland Guardians", shortName: "Guardians",
             abbreviation: "CLE", league: .mlb,
             colorHex: "002b5c", altColorHex: "e31937",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/cle.png"),
        Team(id: "6", name: "Detroit Tigers", shortName: "Tigers",
             abbreviation: "DET", league: .mlb,
             colorHex: "0a2240", altColorHex: "ff4713",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/det.png"),
        Team(id: "7", name: "Kansas City Royals", shortName: "Royals",
             abbreviation: "KC", league: .mlb,
             colorHex: "004687", altColorHex: "7ab2dd",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/kc.png"),
        Team(id: "9", name: "Minnesota Twins", shortName: "Twins",
             abbreviation: "MIN", league: .mlb,
             colorHex: "031f40", altColorHex: "e20e32",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/min.png"),
        // AL West
        Team(id: "18", name: "Houston Astros", shortName: "Astros",
             abbreviation: "HOU", league: .mlb,
             colorHex: "002d62", altColorHex: "eb6e1f",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/hou.png"),
        Team(id: "3", name: "Los Angeles Angels", shortName: "Angels",
             abbreviation: "LAA", league: .mlb,
             colorHex: "ba0021", altColorHex: "c4ced4",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/laa.png"),
        Team(id: "11", name: "Athletics", shortName: "Athletics",
             abbreviation: "ATH", league: .mlb,
             colorHex: "003831", altColorHex: "efb21e",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/oak.png"),
        Team(id: "12", name: "Seattle Mariners", shortName: "Mariners",
             abbreviation: "SEA", league: .mlb,
             colorHex: "0c2c56", altColorHex: "005c5c",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/sea.png"),
        Team(id: "13", name: "Texas Rangers", shortName: "Rangers",
             abbreviation: "TEX", league: .mlb,
             colorHex: "003278", altColorHex: "c0111f",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/tex.png"),
        // NL East
        Team(id: "15", name: "Atlanta Braves", shortName: "Braves",
             abbreviation: "ATL", league: .mlb,
             colorHex: "0c2340", altColorHex: "ba0c2f",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/atl.png"),
        Team(id: "28", name: "Miami Marlins", shortName: "Marlins",
             abbreviation: "MIA", league: .mlb,
             colorHex: "00a3e0", altColorHex: "000000",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/mia.png"),
        Team(id: "21", name: "New York Mets", shortName: "Mets",
             abbreviation: "NYM", league: .mlb,
             colorHex: "002d72", altColorHex: "ff5910",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/nym.png"),
        Team(id: "22", name: "Philadelphia Phillies", shortName: "Phillies",
             abbreviation: "PHI", league: .mlb,
             colorHex: "e81828", altColorHex: "003278",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/phi.png"),
        Team(id: "20", name: "Washington Nationals", shortName: "Nationals",
             abbreviation: "WSH", league: .mlb,
             colorHex: "ab0003", altColorHex: "14225a",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/wsh.png"),
        // NL Central
        Team(id: "16", name: "Chicago Cubs", shortName: "Cubs",
             abbreviation: "CHC", league: .mlb,
             colorHex: "0e3386", altColorHex: "cc3433",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/chc.png"),
        Team(id: "17", name: "Cincinnati Reds", shortName: "Reds",
             abbreviation: "CIN", league: .mlb,
             colorHex: "c6011f", altColorHex: "ffffff",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/cin.png"),
        Team(id: "8", name: "Milwaukee Brewers", shortName: "Brewers",
             abbreviation: "MIL", league: .mlb,
             colorHex: "13294b", altColorHex: "ffc72c",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/mil.png"),
        Team(id: "23", name: "Pittsburgh Pirates", shortName: "Pirates",
             abbreviation: "PIT", league: .mlb,
             colorHex: "000000", altColorHex: "fdb827",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/pit.png"),
        Team(id: "24", name: "St. Louis Cardinals", shortName: "Cardinals",
             abbreviation: "STL", league: .mlb,
             colorHex: "c41e3a", altColorHex: "0c2340",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/stl.png"),
        // NL West
        Team(id: "29", name: "Arizona Diamondbacks", shortName: "D-backs",
             abbreviation: "ARI", league: .mlb,
             colorHex: "aa182c", altColorHex: "000000",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/ari.png"),
        Team(id: "27", name: "Colorado Rockies", shortName: "Rockies",
             abbreviation: "COL", league: .mlb,
             colorHex: "33006f", altColorHex: "000000",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/col.png"),
        Team(id: "19", name: "Los Angeles Dodgers", shortName: "Dodgers",
             abbreviation: "LAD", league: .mlb,
             colorHex: "005a9c", altColorHex: "ffffff",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/lad.png"),
        Team(id: "25", name: "San Diego Padres", shortName: "Padres",
             abbreviation: "SD", league: .mlb,
             colorHex: "2f241d", altColorHex: "ffc425",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/sd.png"),
        Team(id: "26", name: "San Francisco Giants", shortName: "Giants",
             abbreviation: "SF", league: .mlb,
             colorHex: "fd5a1e", altColorHex: "000000",
             logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/sf.png"),
    ]

    // 리그별 팀 목록 반환
    static func teams(for league: League) -> [Team] {
        switch league {
        case .kbo: return kboTeams
        case .mlb: return mlbTeams
        }
    }

    // ID로 팀 찾기 (모든 리그에서 검색)
    static func find(by id: String) -> Team? {
        kboTeams.first(where: { $0.id == id }) ?? mlbTeams.first(where: { $0.id == id })
    }
}
