// TeamCharacterView.swift
// Team 모델을 받아 캐릭터를 그리는 편의 래퍼
// 실제 그리기는 Shared/BaseballCharacterView가 담당 (위젯과 공유)

import SwiftUI

struct TeamCharacterView: View {
    let team: Team
    var size: CGFloat = 48

    var body: some View {
        BaseballCharacterView(
            capColor: team.color,
            buttonColor: team.altColor,
            size: size
        )
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
