// MyballWidgetLiveActivity.swift
// 잠금화면 + Dynamic Island에 표시되는 실시간 경기 현황 UI
// 네이버 스포츠의 라이브 잠금화면과 비슷한 구성

import ActivityKit
import WidgetKit
import SwiftUI

struct MyballWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GameActivityAttributes.self) { context in
            // MARK: 잠금화면 UI
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.6))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            // MARK: Dynamic Island UI
            DynamicIsland {
                // 길게 눌렀을 때 확장 화면
                DynamicIslandExpandedRegion(.leading) {
                    teamScoreColumn(
                        code: context.attributes.awayTeamCode,
                        score: context.state.awayScore,
                        highlight: !context.attributes.myTeamIsHome,
                        colorHex: context.attributes.myTeamColorHex
                    )
                }
                DynamicIslandExpandedRegion(.trailing) {
                    teamScoreColumn(
                        code: context.attributes.homeTeamCode,
                        score: context.state.homeScore,
                        highlight: context.attributes.myTeamIsHome,
                        colorHex: context.attributes.myTeamColorHex
                    )
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.statusInfo)
                            .font(.system(size: 13, weight: .bold))
                        MiniDiamond(
                            base1: context.state.base1,
                            base2: context.state.base2,
                            base3: context.state.base3,
                            colorHex: context.attributes.myTeamColorHex,
                            size: 12
                        )
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    CountDots(
                        balls: context.state.balls,
                        strikes: context.state.strikes,
                        outs: context.state.outs
                    )
                }
            } compactLeading: {
                // 축소 상태 왼쪽: 이닝
                Text(context.state.statusInfo)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
            } compactTrailing: {
                // 축소 상태 오른쪽: 스코어
                Text("\(context.state.awayScore):\(context.state.homeScore)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .monospacedDigit()
            } minimal: {
                // 최소 상태 (다른 Activity와 같이 있을 때): 야구공 아이콘
                Image(systemName: "baseball.fill")
                    .font(.system(size: 12))
            }
        }
    }

    // Dynamic Island 확장 화면의 팀+스코어 열
    private func teamScoreColumn(code: String, score: Int, highlight: Bool, colorHex: String) -> some View {
        VStack(spacing: 2) {
            Text(code)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(highlight ? Color(hex: colorHex) : .secondary)
            Text("\(score)")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .monospacedDigit()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - 잠금화면 뷰
private struct LockScreenView: View {
    let context: ActivityViewContext<GameActivityAttributes>

    var body: some View {
        VStack(spacing: 10) {
            // 상단: LIVE 뱃지 + 이닝 + 경기장
            HStack(spacing: 6) {
                if context.state.isFinished {
                    Text("경기 종료")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                } else {
                    Circle().fill(.red).frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.red)
                    Text(context.state.statusInfo)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Spacer()

                if let stadium = context.attributes.stadium {
                    Text(stadium)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // 중앙: 팀 + 스코어 + 다이아몬드
            HStack {
                teamColumn(
                    name: context.attributes.awayTeamName,
                    highlight: !context.attributes.myTeamIsHome
                )

                Spacer()

                Text("\(context.state.awayScore) : \(context.state.homeScore)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Spacer()

                teamColumn(
                    name: context.attributes.homeTeamName,
                    highlight: context.attributes.myTeamIsHome
                )
            }

            // 하단: 다이아몬드 + 볼카운트 + 투수/타자 (경기 중일 때만)
            if !context.state.isFinished {
                HStack(spacing: 16) {
                    MiniDiamond(
                        base1: context.state.base1,
                        base2: context.state.base2,
                        base3: context.state.base3,
                        colorHex: context.attributes.myTeamColorHex,
                        size: 14
                    )

                    CountDots(
                        balls: context.state.balls,
                        strikes: context.state.strikes,
                        outs: context.state.outs
                    )

                    Spacer()

                    // 현재 투수/타자
                    VStack(alignment: .trailing, spacing: 2) {
                        if let pitcher = context.state.pitcherName {
                            Text("P \(pitcher)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        if let batter = context.state.batterName {
                            Text("B \(batter)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
        }
        .padding(14)
    }

    private func teamColumn(name: String, highlight: Bool) -> some View {
        // 내 팀은 굵은 흰색, 상대팀은 반투명 흰색으로 구분
        Text(name)
            .font(.system(size: 15, weight: highlight ? .heavy : .semibold))
            .foregroundStyle(highlight ? .white : .white.opacity(0.65))
    }
}

// MARK: - 미니 다이아몬드 (루상 주자)
private struct MiniDiamond: View {
    let base1: Bool
    let base2: Bool
    let base3: Bool
    let colorHex: String
    let size: CGFloat

    var body: some View {
        ZStack {
            square(occupied: base2).offset(y: -size * 0.75)   // 2루
            square(occupied: base3).offset(x: -size * 0.75)   // 3루
            square(occupied: base1).offset(x: size * 0.75)    // 1루
        }
        .frame(width: size * 3, height: size * 2.4)
    }

    private func square(occupied: Bool) -> some View {
        // 주자가 있는 베이스는 노란색 (어두운 배경에서 잘 보임)
        Rectangle()
            .fill(occupied ? Color.yellow : Color.white.opacity(0.25))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(45))
    }
}

// MARK: - 볼카운트 점 (B/S/O)
private struct CountDots: View {
    let balls: Int
    let strikes: Int
    let outs: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            dotRow(label: "B", count: balls, max: 3, color: .green)
            dotRow(label: "S", count: strikes, max: 2, color: .yellow)
            dotRow(label: "O", count: outs, max: 2, color: .red)
        }
    }

    private func dotRow(label: String, count: Int, max: Int, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 10)
            ForEach(0..<max, id: \.self) { index in
                Circle()
                    .fill(index < count ? color : Color.white.opacity(0.25))
                    .frame(width: 7, height: 7)
            }
        }
    }
}
