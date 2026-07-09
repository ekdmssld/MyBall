// NotificationDeepLinkUITests.swift
// 경기 알림 탭 → 라이브 경기 센터 딥링크가 동작하는지 확인하는 UI 테스트

import XCTest

final class NotificationDeepLinkUITests: XCTestCase {

    @MainActor
    func testTappingGameNotificationOpensLiveCenter() throws {
        let app = XCUIApplication()
        // 5초 후 테스트 알림을 발송하는 실행 인자
        app.launchArguments = ["-fireTestNotification"]
        app.launch()

        // 팀이 선택되지 않은 상태면 삼성을 선택 (딥링크는 메인 탭에서만 동작)
        let samsungCard = app.staticTexts["삼성"]
        if samsungCard.waitForExistence(timeout: 3) {
            samsungCard.tap()
        }

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        // 알림 권한 팝업이 뜨면 허용 (한국어/영어 둘 다 대응)
        for label in ["허용", "Allow"] {
            let button = springboard.buttons[label]
            if button.waitForExistence(timeout: 3) {
                button.tap()
                break
            }
        }

        // 홈 화면으로 나가서 알림 배너 대기
        XCUIDevice.shared.press(.home)

        // 알림 배너 탭 (제목 텍스트로 찾기)
        let banner = springboard.staticTexts["경기 시작 30분 전"]
        XCTAssertTrue(banner.waitForExistence(timeout: 15), "알림 배너가 나타나야 함")
        banner.tap()

        // 앱이 열리고 라이브 경기 센터 시트가 표시되어야 함
        let liveCenterTitle = app.staticTexts["경기 센터"]
        XCTAssertTrue(liveCenterTitle.waitForExistence(timeout: 10), "경기 센터 화면이 열려야 함")
    }
}
