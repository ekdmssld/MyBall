// Date+Extensions.swift
// Date 타입에 편리한 기능을 추가하는 확장(extension)
// Swift의 extension = Flutter의 extension methods와 비슷

import Foundation

extension Date {
    // MARK: - ESPN API용 날짜 포맷

    // ESPN API에 보낼 "YYYYMMDD" 형식 문자열
    // 예: 2025-04-05 → "20250405"
    var espnDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return formatter.string(from: self)
    }

    // MARK: - 한국어 날짜 표시

    // "4월 5일 (토)" 형식
    var koreanDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: self)
    }

    // "오후 2:00" 형식 (한국 시간)
    var koreanTimeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: self)
    }

    // "2025년 4월" 형식 (캘린더 헤더용)
    var yearMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: self)
    }

    // MARK: - 날짜 계산 헬퍼

    // 해당 월의 첫째 날
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }

    // 해당 월의 마지막 날
    var endOfMonth: Date {
        let calendar = Calendar.current
        // 다음 달 1일에서 하루 빼면 = 이번 달 마지막 날
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
    }

    // 해당 월의 일수 (28, 29, 30, 31)
    var daysInMonth: Int {
        let calendar = Calendar.current
        return calendar.range(of: .day, in: .month, for: self)!.count
    }

    // 해당 월 1일의 요일 (일=1, 월=2, ... 토=7)
    var firstWeekdayOfMonth: Int {
        let calendar = Calendar.current
        return calendar.component(.weekday, from: startOfMonth)
    }

    // 같은 날짜인지 비교 (시간 무시)
    func isSameDay(as other: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: other)
    }

    // 오늘인지 확인
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    // 이전/다음 달로 이동
    func addingMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self)!
    }
}
