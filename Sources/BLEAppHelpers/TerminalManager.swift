//  TerminalManager.swift
//  Created by Matt Gaidica on 1/24/24.

import Foundation

public class TerminalManager: ObservableObject {
    // Make the shared instance public so it can be accessed by other modules
    public static let shared = TerminalManager()
    @Published public var receivedMessages: [String] = []
    private var lineCount = 0
    
    // Make the addMessage function public so it can be called from outside the package
    public func addMessage(_ message: String) {
        let formattedLine = String(format: "%03d>", lineCount) + " " + message
        lineCount += 1
        DispatchQueue.main.async {
            // Insert at the beginning for newest messages on top
            self.receivedMessages.insert(formattedLine, at: 0)
        }
    }
    
    // singleton pattern
    private init() {}
}
