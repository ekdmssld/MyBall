// WallpaperGeneratorView.swift
// 팀 컬러 기반 배경화면 생성 + 사진첩 저장
// Flutter의 RepaintBoundary → toImage()와 비슷한 ImageRenderer 사용

import SwiftUI

// 배경화면 스타일
enum WallpaperStyle: String, CaseIterable, Identifiable {
    case basic = "기본"
    case dark = "다크"
    case vivid = "비비드"

    var id: String { rawValue }
}

struct WallpaperGeneratorView: View {
    let game: Game
    let myTeamId: String

    @State private var selectedStyle: WallpaperStyle = .basic
    @State private var showSaveAlert = false
    @State private var saveMessage = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.large) {
                // 스타일 선택
                stylePicker

                // 미리보기
                wallpaperPreview
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 10)
                    .padding(.horizontal, 40)

                // 저장 버튼
                saveButton
            }
            .padding(Theme.Spacing.large)
            .navigationTitle("배경화면 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .alert("배경화면", isPresented: $showSaveAlert) {
                Button("확인") {}
            } message: {
                Text(saveMessage)
            }
        }
    }

    // MARK: - 스타일 선택
    private var stylePicker: some View {
        Picker("스타일", selection: $selectedStyle) {
            ForEach(WallpaperStyle.allCases) { style in
                Text(style.rawValue).tag(style)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - 배경화면 미리보기
    private var wallpaperPreview: some View {
        WallpaperContent(game: game, myTeamId: myTeamId, style: selectedStyle)
            // iPhone 비율 (9:19.5)
            .frame(width: 280, height: 606)
    }

    // MARK: - 저장 버튼
    private var saveButton: some View {
        Button {
            saveWallpaper()
        } label: {
            Label("사진첩에 저장", systemImage: "square.and.arrow.down")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Colors.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
    }

    // MARK: - 사진첩 저장
    private func saveWallpaper() {
        // ImageRenderer: SwiftUI 뷰를 이미지로 변환 (iOS 16+)
        let renderer = ImageRenderer(
            content: WallpaperContent(game: game, myTeamId: myTeamId, style: selectedStyle)
                .frame(width: 1170, height: 2532) // iPhone 15 Pro 해상도
        )
        renderer.scale = 1.0 // 이미 고해상도 프레임 지정

        guard let uiImage = renderer.uiImage else {
            saveMessage = "이미지 생성에 실패했습니다."
            showSaveAlert = true
            return
        }

        // 사진첩에 저장
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        saveMessage = "배경화면이 사진첩에 저장되었습니다!"
        showSaveAlert = true
    }
}

// MARK: - 배경화면 콘텐츠 (실제 렌더링되는 뷰)
// 별도 struct로 분리 — ImageRenderer에서 재사용하기 위해
struct WallpaperContent: View {
    let game: Game
    let myTeamId: String
    let style: WallpaperStyle

    private var team: Team? {
        Team.find(by: myTeamId)
    }

    var body: some View {
        ZStack {
            // 배경 그라데이션
            background

            // 경기 정보 오버레이
            VStack(spacing: 20) {
                Spacer()
                Spacer()

                // 팀 이름
                Text(team?.name ?? "")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(textColor)

                Spacer()

                // 경기 정보 카드
                gameInfoCard

                Spacer()
                Spacer()
                Spacer()
            }
            .padding(30)
        }
    }

    // MARK: - 배경
    @ViewBuilder
    private var background: some View {
        let teamColor = team?.color ?? Theme.Colors.primary

        switch style {
        case .basic:
            // 팀 컬러 → 흰색 그라데이션
            LinearGradient(
                colors: [teamColor, teamColor.opacity(0.6), .white],
                startPoint: .top,
                endPoint: .bottom
            )
        case .dark:
            // 검정 → 팀 컬러 그라데이션
            LinearGradient(
                colors: [.black, teamColor.opacity(0.8), .black],
                startPoint: .top,
                endPoint: .bottom
            )
        case .vivid:
            // 팀 컬러 + 보조 색상 그라데이션
            let altColor = team?.altColor ?? .orange
            LinearGradient(
                colors: [teamColor, altColor, teamColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - 경기 정보 카드
    private var gameInfoCard: some View {
        let opponent = game.opponent(myTeamId: myTeamId)
        let isHome = game.isHome(teamId: myTeamId)

        return VStack(spacing: 12) {
            Text("NEXT GAME")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(textColor.opacity(0.7))

            // 상대팀
            Text(isHome ? "vs \(opponent.name)" : "@ \(opponent.name)")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(textColor)

            // 날짜 + 시간
            Text(game.date.koreanDateString)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(textColor.opacity(0.9))

            Text(game.date.koreanTimeString)
                .font(.system(size: 14))
                .foregroundStyle(textColor.opacity(0.7))

            // 경기장
            if let venue = game.venue {
                Text(venue)
                    .font(.system(size: 13))
                    .foregroundStyle(textColor.opacity(0.6))
            }

            // 홈/원정 배지
            Text(isHome ? "HOME" : "AWAY")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(style == .dark ? .black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(textColor.opacity(0.8))
                .clipShape(Capsule())
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // 텍스트 색상 (다크 스타일이면 흰색, 나머지는 상황에 따라)
    private var textColor: Color {
        switch style {
        case .dark: return .white
        case .basic: return .primary
        case .vivid: return .white
        }
    }
}

#Preview {
    WallpaperGeneratorView(
        game: Game(
            id: "preview-1",
            date: Date().addingTimeInterval(86400),
            homeTeam: GameTeam(teamId: "10", name: "New York Yankees", abbreviation: "NYY", logoURL: nil, score: nil, isWinner: false),
            awayTeam: GameTeam(teamId: "2", name: "Boston Red Sox", abbreviation: "BOS", logoURL: nil, score: nil, isWinner: false),
            venue: "Yankee Stadium",
            status: .scheduled,
            league: .mlb
        ),
        myTeamId: "10"
    )
}
