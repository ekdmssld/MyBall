// WallpaperRenderTests.swift
// 배경화면이 정상적으로 이미지로 렌더링되는지 확인
// 결과 PNG를 임시 폴더에 저장해서 눈으로도 확인 가능

import Testing
import SwiftUI
@testable import Myball

struct WallpaperRenderTests {

    private func makeKBOGame() -> Game {
        Game(
            id: "render-test",
            date: Date().addingTimeInterval(86400),
            homeTeam: GameTeam(teamId: "kbo-samsung", name: "삼성 라이온즈",
                               abbreviation: "SSL", logoURL: nil, score: nil, isWinner: false),
            awayTeam: GameTeam(teamId: "kbo-lg", name: "LG 트윈스",
                               abbreviation: "LG", logoURL: nil, score: nil, isWinner: false),
            venue: "대구",
            status: .scheduled,
            league: .kbo
        )
    }

    @Test("배경화면 3가지 스타일 모두 렌더링 성공")
    @MainActor
    func allStylesRender() throws {
        for style in WallpaperStyle.allCases {
            let renderer = ImageRenderer(
                content: WallpaperContent(game: makeKBOGame(), myTeamId: "kbo-samsung", style: style)
                    .frame(width: 390, height: 844)
            )
            renderer.scale = 1.0

            let image = renderer.uiImage
            #expect(image != nil, "\(style.rawValue) 스타일이 렌더링되어야 함")

            // 눈으로 확인할 수 있게 PNG 저장
            if let data = image?.pngData() {
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("wallpaper_\(style.rawValue).png")
                try? data.write(to: url)
                print("[렌더테스트] \(style.rawValue): \(url.path)")
            }
        }
    }
}
