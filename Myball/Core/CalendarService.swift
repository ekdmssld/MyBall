// CalendarService.swift
// iOS 캘린더(EventKit)에 경기 일정을 추가하는 서비스
// Flutter에서는 device_calendar 패키지와 비슷한 역할

import EventKit
import Foundation

final class CalendarService {
    // EKEventStore: iOS 캘린더 데이터에 접근하는 객체
    private let eventStore = EKEventStore()

    // MARK: - 권한 요청
    // iOS 17+에서는 requestFullAccessToEvents() 사용
    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    // MARK: - 경기를 캘린더에 추가
    // 성공 시 nil, 실패 시 에러 메시지 반환
    func addGameToCalendar(_ game: Game, myTeamId: String) async -> String? {
        // 권한 확인
        let granted = await requestAccess()
        guard granted else {
            return "캘린더 접근 권한이 없습니다.\n설정 > MyBall > 캘린더에서 허용해주세요."
        }

        // 중복 확인 — 같은 경기 ID로 이미 추가된 이벤트가 있는지
        if isEventAlreadyAdded(gameId: game.id) {
            return "이미 캘린더에 추가된 경기입니다."
        }

        // EKEvent 생성
        let event = EKEvent(eventStore: eventStore)

        let opponent = game.opponent(myTeamId: myTeamId)
        let isHome = game.isHome(teamId: myTeamId)
        let myTeam = game.myTeam(myTeamId: myTeamId)

        // 제목: "삼성 vs 두산" 또는 "Yankees @ Red Sox"
        event.title = isHome
            ? "\(myTeam.abbreviation) vs \(opponent.abbreviation)"
            : "\(myTeam.abbreviation) @ \(opponent.abbreviation)"

        // 시간
        event.startDate = game.date
        event.endDate = game.date.addingTimeInterval(3 * 60 * 60) // 약 3시간

        // 장소
        if let venue = game.venue {
            event.location = venue
        }

        // 알림 (1시간 전)
        event.addAlarm(EKAlarm(relativeOffset: -60 * 60))

        // 메모에 경기 ID 저장 (중복 방지용)
        event.notes = "MyBall Game ID: \(game.id)"

        // 기본 캘린더에 저장
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            return nil // 성공
        } catch {
            return "캘린더 저장 실패: \(error.localizedDescription)"
        }
    }

    // MARK: - 중복 확인
    private func isEventAlreadyAdded(gameId: String) -> Bool {
        // 오늘부터 1년 범위에서 검색
        let startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        let endDate = Date().addingTimeInterval(365 * 24 * 60 * 60)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)

        return events.contains { event in
            event.notes?.contains("MyBall Game ID: \(gameId)") == true
        }
    }
}
