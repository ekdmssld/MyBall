// APIError.swift
// 네트워크 에러를 구분하기 위한 공용 에러 타입

import Foundation

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
