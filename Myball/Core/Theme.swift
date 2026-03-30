// Theme.swift
// 앱 전체 디자인 토큰 (색상, 폰트, 간격)

import SwiftUI

// Flutter의 ThemeData와 비슷한 역할
enum Theme {
    // MARK: - Colors
    enum Colors {
        static let primary = Color.blue
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let label = Color(.label)
        static let secondaryLabel = Color(.secondaryLabel)

        // 홈/원정 경기 구분 색상
        static let home = Color.blue.opacity(0.15)
        static let away = Color.orange.opacity(0.15)

        // 경기 상태 색상
        static let scheduled = Color.gray
        static let inProgress = Color.green
        static let final_ = Color(.label)

        // 요일 색상
        static let sunday = Color.red
        static let saturday = Color.blue
    }

    // MARK: - Fonts
    enum Fonts {
        static let title = Font.title2.bold()
        static let headline = Font.headline
        static let body = Font.body
        static let caption = Font.caption
        static let calendarDay = Font.system(size: 12, weight: .medium)
        static let calendarGame = Font.system(size: 10)
        static let teamName = Font.system(size: 14, weight: .semibold)
    }

    // MARK: - Spacing
    enum Spacing {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
}
