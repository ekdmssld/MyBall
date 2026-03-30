// APIClient.swift
// ESPN API 호출을 담당하는 네트워크 클라이언트 (싱글톤)

import Foundation

// MARK: - API 에러 타입
// 네트워크 에러를 구분하기 위한 enum
enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)       // HTTP 상태 코드
    case noData

    // LocalizedError를 채택하면 에러 메시지를 커스텀할 수 있음
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .decodingError(let error):
            return "데이터 변환 오류: \(error.localizedDescription)"
        case .serverError(let code):
            return "서버 오류 (HTTP \(code))"
        case .noData:
            return "데이터가 없습니다."
        }
    }
}

// MARK: - API 클라이언트
// @MainActor 없음 — 네트워크 호출은 백그라운드에서 실행
final class APIClient {
    // 싱글톤: 앱 전체에서 하나의 인스턴스만 사용
    // Flutter의 static final instance = APIClient._() 패턴과 비슷
    static let shared = APIClient()

    // URLSession: iOS의 HTTP 클라이언트 (Flutter의 http 패키지와 비슷)
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15  // 요청 타임아웃 15초
        config.timeoutIntervalForResource = 30 // 리소스 타임아웃 30초
        session = URLSession(configuration: config)
    }

    // MARK: - 스코어보드 조회
    // 특정 날짜의 경기 목록을 가져옴
    // async throws: 비동기 + 에러 발생 가능 (Flutter의 Future와 비슷)
    func fetchScoreboard(league: League, date: Date) async throws -> [Game] {
        let urlString = Constants.scoreboardURL(
            league: league.espnPath,
            date: date.espnDateString
        )

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        // URLSession의 data(from:) 은 async/await를 지원
        let (data, response) = try await session.data(from: url)

        // HTTP 응답 상태 코드 확인
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(httpResponse.statusCode)
        }

        // JSON → DTO 변환
        let decoder = JSONDecoder()
        let scoreboardResponse: ESPNScoreboardResponse
        do {
            scoreboardResponse = try decoder.decode(ESPNScoreboardResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }

        // DTO → Domain 모델 변환
        // compactMap: nil을 자동 제거 (Flutter의 whereType과 비슷)
        let games = scoreboardResponse.events?.compactMap { event in
            event.toDomain(league: league)
        } ?? []

        return games
    }

    // MARK: - 팀 목록 조회
    // ESPN에서 팀 목록을 가져옴 (디버그/확인용)
    func fetchTeams(league: League) async throws -> [ESPNTeam] {
        let urlString = Constants.teamsURL(league: league.espnPath)

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let teamsResponse: ESPNTeamsResponse
        do {
            teamsResponse = try decoder.decode(ESPNTeamsResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }

        // 중첩된 구조에서 팀 배열 추출
        let teams = teamsResponse.sports?.first?.leagues?.first?.teams?.compactMap { $0.team } ?? []
        return teams
    }

    // MARK: - Raw JSON 조회 (디버그용)
    #if DEBUG
    func fetchRawJSON(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, _) = try await session.data(from: url)

        // JSON을 보기 좋게 포맷팅
        if let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }

        return String(data: data, encoding: .utf8) ?? "데이터를 문자열로 변환할 수 없습니다."
    }
    #endif
}
