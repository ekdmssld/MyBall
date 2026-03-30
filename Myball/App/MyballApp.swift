// MyballApp.swift
// 앱 진입점 — Flutter의 main.dart + runApp()과 비슷

import SwiftUI
import SwiftData

// @main: 앱의 시작점 (Flutter의 void main() => runApp())
@main
struct MyballApp: App {
    // SwiftData 모델 컨테이너 (로컬 DB)
    // Phase 3에서는 아직 SwiftData 모델이 없으므로 빈 스키마 사용
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("ModelContainer를 생성할 수 없습니다: \(error)")
        }
    }()

    // body: 앱의 화면 구성 (Flutter의 MaterialApp build와 비슷)
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
