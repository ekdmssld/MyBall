// TeamCharacterView.swift
// 팀 컬러 모자를 쓴 귀여운 야구공 캐릭터
// 이미지 파일 없이 SwiftUI 도형만으로 그려서 어떤 크기에서도 선명함
// (실제 구단 마스코트 이미지는 저작권 문제가 있어 자체 캐릭터를 사용)

import SwiftUI

struct TeamCharacterView: View {
    let team: Team
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            ball        // 야구공 몸통
            seams       // 빨간 실밥
            face        // 눈, 볼터치, 입
            cap         // 팀 컬러 모자
        }
        .frame(width: size, height: size * 1.1)
    }

    // MARK: - 야구공 몸통
    private var ball: some View {
        Circle()
            .fill(
                // 위쪽이 살짝 밝은 그라데이션 → 입체감
                LinearGradient(
                    colors: [Color.white, Color(white: 0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(Circle().stroke(Color(white: 0.75), lineWidth: size * 0.02))
            .frame(width: size, height: size)
            .offset(y: size * 0.05)
    }

    // MARK: - 실밥 (좌우 곡선)
    // 공 바깥에 중심을 둔 원 두 개를 점선으로 그리고, 공 모양으로 잘라내면
    // 안쪽에 곡선 실밥만 남음
    private var seams: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.red.opacity(0.75),
                    style: StrokeStyle(lineWidth: size * 0.035, dash: [size * 0.05, size * 0.05])
                )
                .frame(width: size, height: size)
                .offset(x: -size * 0.72)
            Circle()
                .stroke(
                    Color.red.opacity(0.75),
                    style: StrokeStyle(lineWidth: size * 0.035, dash: [size * 0.05, size * 0.05])
                )
                .frame(width: size, height: size)
                .offset(x: size * 0.72)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .offset(y: size * 0.05)
    }

    // MARK: - 얼굴
    private var face: some View {
        ZStack {
            // 눈 (반짝임 포함)
            eye.offset(x: -size * 0.15, y: size * 0.08)
            eye.offset(x: size * 0.15, y: size * 0.08)

            // 볼터치 (분홍)
            blush.offset(x: -size * 0.28, y: size * 0.20)
            blush.offset(x: size * 0.28, y: size * 0.20)

            // 웃는 입
            SmileShape()
                .stroke(Color.black.opacity(0.8), style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
                .frame(width: size * 0.2, height: size * 0.09)
                .offset(y: size * 0.24)
        }
    }

    private var eye: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.85))
                .frame(width: size * 0.09, height: size * 0.09)
            // 눈 반짝임
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.03, height: size * 0.03)
                .offset(x: -size * 0.015, y: -size * 0.015)
        }
    }

    private var blush: some View {
        Circle()
            .fill(Color.pink.opacity(0.35))
            .frame(width: size * 0.11, height: size * 0.11)
    }

    // MARK: - 팀 컬러 모자
    private var cap: some View {
        ZStack {
            // 모자 돔 (원의 위쪽 절반만 마스크로 남김)
            Circle()
                .fill(team.color)
                .frame(width: size * 0.72, height: size * 0.72)
                .mask(
                    Rectangle()
                        .frame(width: size * 0.72, height: size * 0.36)
                        .offset(y: -size * 0.18)
                )
                .offset(y: -size * 0.10)

            // 모자 챙
            Capsule()
                .fill(team.color)
                .frame(width: size * 0.82, height: size * 0.10)
                .offset(y: -size * 0.28)

            // 모자 꼭지 단추 (보조 색상)
            Circle()
                .fill(team.altColor)
                .frame(width: size * 0.08, height: size * 0.08)
                .offset(y: -size * 0.47)
        }
    }
}

// MARK: - 웃는 입 모양
// 아래로 볼록한 곡선 (QuadCurve = 제어점 하나로 그리는 곡선)
private struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY + rect.height)
        )
        return path
    }
}

// MARK: - 미리보기: KBO 10개 팀 전부
#Preview {
    let columns = Array(repeating: GridItem(.flexible()), count: 5)
    return LazyVGrid(columns: columns, spacing: 20) {
        ForEach(Team.kboTeams) { team in
            VStack(spacing: 6) {
                TeamCharacterView(team: team, size: 52)
                Text(team.shortName).font(.caption)
            }
        }
    }
    .padding()
}
