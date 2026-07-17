//
//  CustomSmartFeedDelegate.swift
//  NetNewsWire
//
//  Backs a user-created smart feed, fetching articles that match its criteria.
//

import Foundation
import RSCore
import Articles
import ArticlesDatabase
import Account
import Images

@MainActor final class CustomSmartFeedDelegate: SmartFeedDelegate {

	let userSmartFeed: UserSmartFeed

	init(userSmartFeed: UserSmartFeed) {
		self.userSmartFeed = userSmartFeed
	}

	var sidebarItemID: SidebarItemIdentifier? {
		// A stable per-feed id (the UUID) — not a type name — so identity survives
		// relaunches, state restoration, and mutation of the smart-feeds array.
		SidebarItemIdentifier.smartFeed(userSmartFeed.id)
	}

	var nameForDisplay: String {
		userSmartFeed.name
	}

	var fetchType: FetchType {
		.smartFeedCriteria(userSmartFeed.criteria)
	}

	var smallIcon: IconImage? {
		Assets.Images.customSmartFeed
	}

	func fetchUnreadCount(account: Account) async -> Int {
		await account.fetchUnreadCountMatchingCriteriaAsync(userSmartFeed.criteria)
	}
}
