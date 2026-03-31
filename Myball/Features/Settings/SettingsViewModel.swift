// SettingsViewModel.swift
// 설정 화면 상태 관리

import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Published 상태
    @Published var selectedTeam: Team?
    @Published var notificationEnabled: Bool {
        didSet { defaults.set(notificationEnabled, forKey: Constants.notificationEnabledKey) }
    }
    @Published var notificationLeadTime: Int {
        didSet { defaults.set(notificationLeadTime, forKey: Constants.notificationLeadTimeKey) }
    }
    @Published var showTeamSelection = false
    @Published var showClearCacheAlert = false
    @Published var pendingNotificationCount = 0

    // 의존성
    private let teamRepository = TeamRepository()
    private let notificationService = NotificationService()
    private let defaults = UserDefaults(suiteName: Constants.appGroupID) ?? .standard

    // 알림 시간 옵션
    let leadTimeOptions = [30, 60, 120]

    init() {
        self.selectedTeam = teamRepository.getSelectedTeam()
        self.notificationEnabled = defaults.bool(forKey: Constants.notificationEnabledKey)
        self.notificationLeadTime = defaults.integer(forKey: Constants.notificationLeadTimeKey)
        // 기본값 60분 (처음 설정 시 0이 되므로)
        if notificationLeadTime == 0 { notificationLeadTime = 60 }
    }

    // MARK: - 알림 시간 표시 텍스트
    func leadTimeText(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)분 전"
        } else {
            return "\(minutes / 60)시간 전"
        }
    }

    // MARK: - 팀 변경
    func changeTeam() {
        teamRepository.clearSelectedTeam()
    }

    // MARK: - 캐시 삭제
    func clearCache() {
        ScheduleCache.shared.clearAll()
    }

    // MARK: - 알림 토글
    func toggleNotification() async {
        if notificationEnabled {
            let granted = await notificationService.requestPermission()
            if !granted {
                notificationEnabled = false
            }
        } else {
            notificationService.cancelAllNotifications()
        }
    }

    // MARK: - 예약된 알림 수 로드
    func loadPendingCount() async {
        pendingNotificationCount = await notificationService.pendingNotificationCount()
    }

    // MARK: - 앱 버전
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
