// NotificationDelegate.swift
// 알림 탭 이벤트를 받아서 SwiftUI 화면 전환으로 연결하는 델리게이트
// 흐름: 경기 알림 탭 → liveCenterRequest 발행 → RootView가 감지해서 경기 센터 시트 표시

import UserNotifications
import SwiftUI
import Combine  // ObservableObject, @Published에 필요

struct LiveCenterDeepLinkRequest: Identifiable, Equatable {
    let id = UUID()
    let gameId: String?
    let teamId: String?
}

@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationDelegate()

    // 이전 테스트 코드와 호환하기 위한 열림 상태
    @Published var openLiveCenter = false
    // 값이 들어오면 RootView가 라이브 경기 센터를 시트로 띄움
    @Published var liveCenterRequest: LiveCenterDeepLinkRequest?

    // MARK: - 앱이 실행 중일 때도 알림 배너 표시
    // (기본 동작은 앱 실행 중이면 알림을 숨김)
    // nonisolated: 이 메서드는 시스템이 아무 스레드에서나 호출할 수 있음
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    // MARK: - 알림 탭 처리
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let category = response.notification.request.content.categoryIdentifier
        let userInfo = response.notification.request.content.userInfo
        let destination = userInfo[Constants.notificationDestinationKey] as? String

        // 경기 시작 알림이면 라이브 경기 센터 열기
        if category == Constants.notificationCategoryGameStart ||
            destination == Constants.notificationDestinationLiveCenter {
            let gameId = userInfo[Constants.notificationGameIdKey] as? String
            let teamId = userInfo[Constants.notificationTeamIdKey] as? String

            await MainActor.run {
                self.requestLiveCenter(gameId: gameId, teamId: teamId)
            }
        }
    }

    func requestLiveCenter(gameId: String? = nil, teamId: String? = nil) {
        liveCenterRequest = LiveCenterDeepLinkRequest(gameId: gameId, teamId: teamId)
        openLiveCenter = true
    }

    func clearLiveCenterRequest() {
        liveCenterRequest = nil
        openLiveCenter = false
    }
}
