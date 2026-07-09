// LiveActivityUITests.swift
// Live Activity가 홈 화면(Dynamic Island)에 표시되는지 확인하는 UI 테스트
// 앱을 더미 모드로 실행 → 홈 화면으로 나감 → 그 사이 외부에서 스크린샷 검증

import XCTest

final class LiveActivityUITests: XCTestCase {

    @MainActor
    func testDummyLiveActivityShowsOnHomeScreen() throws {
        let app = XCUIApplication()
        // 더미 Live Activity를 자동 시작하는 실행 인자
        app.launchArguments = ["-liveActivityDummy"]
        app.launch()

        // Activity 시작을 기다림
        sleep(5)

        // 홈 화면으로 나가기 (앱이 백그라운드로 가면 Dynamic Island에 표시됨)
        XCUIDevice.shared.press(.home)
        sleep(8)

        // 기기 잠금 → 다시 깨우면 잠금화면에 Live Activity가 보여야 함
        // (pressLockButton은 시뮬레이터 테스트에서 쓰는 비공개 API)
        XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
        sleep(2)
        XCUIDevice.shared.press(.home)  // 화면 깨우기 (잠금화면 표시)

        // 외부(simctl)에서 스크린샷을 찍을 시간을 확보
        sleep(25)
    }
}
