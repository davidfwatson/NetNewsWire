//
//  UserSmartFeedsFile.swift
//  NetNewsWire
//
//  Reads and writes the user's custom smart-feed definitions to disk.
//

import Foundation
import os.log
import RSCore

@MainActor final class UserSmartFeedsFile {

	private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UserSmartFeedsFile")
	private let fileURL = AppConfig.dataFolder.appendingPathComponent("SmartFeeds.json")

	func load() -> [UserSmartFeed] {
		guard let data = try? Data(contentsOf: fileURL) else {
			return []
		}
		do {
			return try JSONDecoder().decode([UserSmartFeed].self, from: data)
		} catch {
			Self.logger.error("Error reading custom smart feeds: \(error.localizedDescription, privacy: .public)")
			return []
		}
	}

	func save(_ userSmartFeeds: [UserSmartFeed]) {
		do {
			let data = try JSONEncoder().encode(userSmartFeeds)
			try data.write(to: fileURL)
		} catch {
			Self.logger.error("Error writing custom smart feeds: \(error.localizedDescription, privacy: .public)")
		}
	}
}
