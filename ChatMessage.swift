//
//  ChatMessage.swift
//  Unwind 1_8
//
//  Created by Anastasia Rich on 03/11/2024.
//

import Foundation
import Combine

struct ChatMessage: Identifiable, Equatable { // Conforming to Identifiable and Equatable
    let id: UUID = UUID() // Default value for id, no need to pass explicitly
    let text: String
    let isUser: Bool
}
