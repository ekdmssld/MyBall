// Team.swift
// 야구팀 모델 + KBO 10개 팀 하드코딩 데이터

import SwiftUI

// struct는 Flutter의 class와 비슷하지만, 값 타입(value type)임
// Identifiable: SwiftUI에서 목록 표시에 필요
// Codable: JSON 변환 + UserDefaults 저장에 필요
// Equatable: == 비교에 필요
struct Team: Identifiable, Codable, Equatable, Hashable {
    let id: String           // 팀 ID (kbo-samsung 등)
    let name: String         // 팀 전체 이름 (예: "삼성 라이온즈")
    let shortName: String    // 짧은 이름 (예: "삼성")
    let abbreviation: String // 약칭 (예: "SSL")
    let league: League
    let colorHex: String     // 팀 주 색상 (HEX, # 없이)
    let altColorHex: String  // 팀 보조 색상
    let logoURL: String?     // 로고 URL (현재 미사용 — 캐릭터로 대체)

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

    // 리그별 팀 목록 반환
    static func teams(for league: League) -> [Team] {
        switch league {
        case .kbo: return kboTeams
        }
    }

    // ID로 팀 찾기
    static func find(by id: String) -> Team? {
        kboTeams.first(where: { $0.id == id })
    }
}
