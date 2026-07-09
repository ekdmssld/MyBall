// League.swift
// 리그 enum — 현재는 KBO만 지원
// (과거에 저장된 데이터와의 호환을 위해 enum 형태 유지)

import Foundation

// enum은 Flutter의 enum과 비슷하지만, Swift에서는 프로퍼티와 메서드를 가질 수 있음
// CaseIterable: 모든 케이스를 배열로 접근 가능 (League.allCases)
// Codable: JSON 변환 가능
enum League: String, CaseIterable, Codable, Identifiable {
    case kbo = "kbo"

    // Identifiable을 위한 id (SwiftUI List/ForEach에서 필요)
    var id: String { rawValue }

    // 화면에 표시할 이름
    var displayName: String {
        switch self {
        case .kbo: return "KBO"
        }
    }
}
