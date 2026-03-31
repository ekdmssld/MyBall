// NotificationService.swift
// 로컬 푸시 알림 서비스 — 경기 시작 전 알림 예약
// Flutter의 flutter_local_notifications 패키지와 비슷

import UserNotifications
import Foundation

final class NotificationService {
    // MARK: - 권한 요청
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - 경기 알림 예약
    // leadTimeMinutes: 경기 시작 몇 분 전에 알림할지 (30, 60, 120)
    func scheduleGameNotification(_ game: Game, myTeamId: String, leadTimeMinutes: Int) async {
        let granted = await requestPermission()
        guard granted else { return }

        let opponent = game.opponent(myTeamId: myTeamId)
        let isHome = game.isHome(teamId: myTeamId)

        // 알림 내용
        let content = UNMutableNotificationContent()
        content.title = "경기 시작 \(leadTimeMinutes)분 전"
        content.body = isHome
            ? "vs \(opponent.name) — 홈 경기가 곧 시작됩니다!"
            : "@ \(opponent.name) — 원정 경기가 곧 시작됩니다!"
        content.sound = .default
        content.categoryIdentifier = "gameStart"

        // 알림 시간 계산 (경기 시간 - leadTime)
        let triggerDate = game.date.addingTimeInterval(-Double(leadTimeMinutes * 60))

        // 이미 지난 시간이면 예약하지 않음
        guard triggerDate > Date() else { return }

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // 알림 ID = 경기 ID (중복 방지 및 취소에 사용)
        let request = UNNotificationRequest(
            identifier: "game-\(game.id)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // 알림 예약 실패는 조용히 무시 (크리티컬하지 않음)
        }
    }

    // MARK: - 특정 경기 알림 취소
    func cancelNotification(for gameId: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["game-\(gameId)"])
    }

    // MARK: - 모든 알림 취소
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - 예약된 알림 수 확인
    func pendingNotificationCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.count
    }
}
