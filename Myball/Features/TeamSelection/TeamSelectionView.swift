// TeamSelectionView.swift
// 팀 선택 화면 — 리그 선택 → 팀 그리드 → 탭하여 선택
// Flutter의 StatefulWidget + GridView와 비슷

import SwiftUI
import Kingfisher

struct TeamSelectionView: View {
    // @StateObject: ViewModel 생성 및 소유 (이 뷰가 사라지면 ViewModel도 해제)
    // Flutter의 ChangeNotifierProvider와 비슷
    @StateObject private var viewModel = TeamSelectionViewModel()

    // 팀 그리드: 3열
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 상단 헤더
            headerSection

            // 리그 선택 세그먼트
            leaguePicker

            // 검색바
            searchBar

            // 팀 그리드
            teamGrid
        }
        .background(Theme.Colors.background)
    }

    // MARK: - 헤더
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "baseball")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.primary)
                .padding(.top, Theme.Spacing.extraLarge)

            Text("MyBall")
                .font(.largeTitle.bold())

            Text("응원하는 팀을 선택하세요")
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.bottom, Theme.Spacing.large)
    }

    // MARK: - 리그 선택
    private var leaguePicker: some View {
        Picker("리그", selection: $viewModel.selectedLeague) {
            ForEach(League.allCases) { league in
                Text(league.displayName).tag(league)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.bottom, Theme.Spacing.medium)
    }

    // MARK: - 검색바
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Colors.secondaryLabel)
            TextField("팀 이름 검색", text: $viewModel.searchText)
                .textFieldStyle(.plain)
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.bottom, Theme.Spacing.medium)
    }

    // MARK: - 팀 그리드
    private var teamGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.filteredTeams) { team in
                    TeamCard(team: team) {
                        viewModel.selectTeam(team)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.bottom, Theme.Spacing.extraLarge)
        }
    }
}

// MARK: - 팀 카드 (그리드 아이템)
// 별도 struct로 분리 — body를 짧게 유지하기 위한 SwiftUI 패턴
private struct TeamCard: View {
    let team: Team
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Theme.Spacing.medium) {
                // 팀 로고 또는 이니셜
                teamLogo

                // 팀 이름
                Text(team.shortName)
                    .font(Theme.Fonts.teamName)
                    .foregroundStyle(Theme.Colors.label)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.large)
            .background(team.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(team.color.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // 로고가 있으면 Kingfisher로 로드, 없으면 이니셜 원형 표시
    @ViewBuilder
    private var teamLogo: some View {
        if let logoURL = team.logoURL, let url = URL(string: logoURL) {
            // Kingfisher: 이미지 다운로드 + 캐싱 라이브러리
            // Flutter의 cached_network_image와 비슷
            KFImage(url)
                .placeholder {
                    teamInitial
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
        } else {
            teamInitial
        }
    }

    // 로고 없을 때 보여줄 이니셜 뷰 (KBO 팀용)
    private var teamInitial: some View {
        Circle()
            .fill(team.color)
            .frame(width: 48, height: 48)
            .overlay(
                Text(team.abbreviation.prefix(2))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            )
    }
}

#Preview {
    TeamSelectionView()
}
