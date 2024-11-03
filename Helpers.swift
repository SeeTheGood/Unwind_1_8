//
//  Helpers.swift
//  Unwind 1_8
//
//  Created by Anastasia Rich on 03/11/2024.
//

import Foundation
import Combine

// MARK: - JSON Encoding and Decoding Helpers

/// Encodes an encodable object to JSON data.
func encodeToJSON<T: Encodable>(_ value: T) -> Data? {
    do {
        return try JSONEncoder().encode(value)
    } catch {
        print("JSON Encoding Error: \(error.localizedDescription)")
        return nil
    }
}

/// Decodes JSON data into a decodable object of a specified type.
func decodeFromJSON<T: Decodable>(_ data: Data, type: T.Type) -> T? {
    do {
        return try JSONDecoder().decode(type, from: data)
    } catch {
        print("JSON Decoding Error: \(error.localizedDescription)")
        return nil
    }
}

// MARK: - Error Handling Helper

/// Parses an error and returns a user-friendly description.
func handleError(_ error: Error) -> String {
    if let urlError = error as? URLError {
        return "Network error: \(urlError.localizedDescription)"
    } else {
        return "Unexpected error: \(error.localizedDescription)"
    }
}

// MARK: - Retry Logic Helper

/// Retries a Combine publisher a specified number of times.
func retry<T>(_ publisher: AnyPublisher<T, Error>, retries: Int) -> AnyPublisher<T, Error> {
    publisher.retry(retries).eraseToAnyPublisher()
}
