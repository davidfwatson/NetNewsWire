//
//  SmartFeedsController.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 12/16/17.
//  Copyright © 2017 Ranchero Software. All rights reserved.
//

import Foundation
import RSCore
import Account

@MainActor final class SmartFeedsController: DisplayNameProvider, ContainerIdentifiable {
	nonisolated let containerID: ContainerIdentifier? = ContainerIdentifier.smartFeedController

	public static let shared = SmartFeedsController()
	let nameForDisplay = NSLocalizedString("Smart Feeds", comment: "Smart Feeds group title")

	var smartFeeds = [SidebarItem]()
	let todayFeed = SmartFeed(delegate: TodayFeedDelegate())
	let unreadFeed = UnreadFeed()
	let starredFeed = SmartFeed(delegate: StarredFeedDelegate())

	/// The user-created smart feeds, in display order.
	private(set) var userSmartFeeds = [UserSmartFeed]()

	private let userSmartFeedsFile = UserSmartFeedsFile()
	private var customSmartFeedsByID = [String: SmartFeed]()

	private init() {
		userSmartFeeds = userSmartFeedsFile.load()
		rebuildSmartFeeds()
	}

	func find(by identifier: SidebarItemIdentifier) -> PseudoFeed? {
		switch identifier {
		case .smartFeed(let stringIdentifer):
			switch stringIdentifer {
			case String(describing: TodayFeedDelegate.self):
				return todayFeed
			case String(describing: UnreadFeed.self):
				return unreadFeed
			case String(describing: StarredFeedDelegate.self):
				return starredFeed
			default:
				return customSmartFeedsByID[stringIdentifer]
			}
		default:
			return nil
		}
	}

	// MARK: - Custom Smart Feeds

	/// The `UserSmartFeed` definition for a sidebar identifier, or `nil` if it isn't a
	/// user-created smart feed (i.e. it's one of the three built-ins, or not a smart feed).
	func userSmartFeed(for identifier: SidebarItemIdentifier?) -> UserSmartFeed? {
		guard let identifier, case .smartFeed(let id) = identifier else {
			return nil
		}
		return userSmartFeeds.first { $0.id == id }
	}

	func addUserSmartFeed(_ userSmartFeed: UserSmartFeed) {
		userSmartFeeds.append(userSmartFeed)
		persistAndRebuild()
	}

	func updateUserSmartFeed(_ userSmartFeed: UserSmartFeed) {
		guard let index = userSmartFeeds.firstIndex(where: { $0.id == userSmartFeed.id }) else {
			return
		}
		userSmartFeeds[index] = userSmartFeed
		persistAndRebuild()
	}

	func removeUserSmartFeed(_ userSmartFeed: UserSmartFeed) {
		userSmartFeeds.removeAll { $0.id == userSmartFeed.id }
		persistAndRebuild()
	}

	// MARK: - Private

	private func rebuildSmartFeeds() {
		var wrappers = [SmartFeed]()
		var byID = [String: SmartFeed]()
		for userSmartFeed in userSmartFeeds {
			let feed = SmartFeed(delegate: CustomSmartFeedDelegate(userSmartFeed: userSmartFeed))
			wrappers.append(feed)
			byID[userSmartFeed.id] = feed
		}
		customSmartFeedsByID = byID
		smartFeeds = [todayFeed, unreadFeed, starredFeed] + wrappers
	}

	private func persistAndRebuild() {
		userSmartFeedsFile.save(userSmartFeeds)
		rebuildSmartFeeds()
		// Both the Mac sidebar and the iOS sidebar rebuild their trees from
		// `smartFeeds` when this notification fires.
		NotificationCenter.default.post(name: .ChildrenDidChange, object: self)
	}
}
