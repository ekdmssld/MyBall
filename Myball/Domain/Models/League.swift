// League.swift
// KBO / MLB 리그를 구분하는 enum

import Foundation

// enum은 Flutter의 enum과 비슷하지만, Swift에서는 프로퍼티와 메서드를 가질 수 있음
// CaseIterable: 모든 케이스를 배열로 접근 가능 (League.allCases)
// Codable: JSON 변환 가능
enum League: String, CaseIterable, Codable, Identifiable {
    case kbo = "kbo"
    case mlb = "mlb"

    // Identifiable을 위한 id (SwiftUI List/ForEach에서 필요)
    var id: String { rawValue }

    // 화면에 표시할 이름
    var displayName: String {
        switch self {
        case .kbo: return "KBO"
        case .mlb: return "MLB"
        }
    }

    // ESPN API 경로에 사용할 문자열
    var espnPath: String {
        rawValue
    }
}
