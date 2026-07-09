// BaseballCharacterView.swift
// 모자를 쓴 귀여운 야구공 캐릭터 (색상만 받는 순수 버전)
// ⚠️ 메인 앱과 위젯 익스텐션 양쪽 타겟에 모두 포함됨
//    Team 모델에 의존하지 않아서 어느 타겟에서든 사용 가능

import SwiftUI

struct BaseballCharacterView: View {
    let capColor: Color      // 모자 색 (팀 주 색상)
    let buttonColor: Color   // 모자 꼭지 단추 색 (팀 보조 색상)
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            ball        // 야구공 몸통
            seams       // 빨간 실밥
            face        // 눈, 볼터치, 입
            cap         // 모자
        }
        .frame(width: size, height: size * 1.1)
        // 장식용 이미지이므로 VoiceOver가 읽지 않도록 숨김
        .accessibilityHidden(true)
    }

    // MARK: - 야구공 몸통
    private var ball: some View {
        Circle()
            .fill(
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

    // MARK: - 실밥
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
            eye.offset(x: -size * 0.15, y: size * 0.08)
            eye.offset(x: size * 0.15, y: size * 0.08)

            blush.offset(x: -size * 0.28, y: size * 0.20)
            blush.offset(x: size * 0.28, y: size * 0.20)

            CharacterSmileShape()
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

    // MARK: - 모자
    private var cap: some View {
        ZStack {
            Circle()
                .fill(capColor)
                .frame(width: size * 0.72, height: size * 0.72)
                .mask(
                    Rectangle()
                        .frame(width: size * 0.72, height: size * 0.36)
                        .offset(y: -size * 0.18)
                )
                .offset(y: -size * 0.10)

            Capsule()
                .fill(capColor)
                .frame(width: size * 0.82, height: size * 0.10)
                .offset(y: -size * 0.28)

            Circle()
                .fill(buttonColor)
                .frame(width: size * 0.08, height: size * 0.08)
                .offset(y: -size * 0.47)
        }
    }
}

// MARK: - 웃는 입 모양
struct CharacterSmileShape: Shape {
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
