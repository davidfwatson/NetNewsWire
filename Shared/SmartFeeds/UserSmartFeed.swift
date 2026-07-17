//
//  UserSmartFeed.swift
//  NetNewsWire
//
//  A user-created smart feed: a name plus the criteria that define it.
//

import Foundation
import ArticlesDatabase

struct UserSmartFeed: Codable, Identifiable, Hashable {

	let id: String
	var name: String
	var criteria: SmartFeedCriteria

	init(id: String = UUID().uuidString, name: String, criteria: SmartFeedCriteria) {
		self.id = id
		self.name = name
		self.criteria = criteria
	}
}
