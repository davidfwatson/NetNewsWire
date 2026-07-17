//
//  SmartFeedEditorModel.swift
//  NetNewsWire
//
//  Backs the shared SwiftUI editor for creating and editing custom smart feeds.
//

import Foundation
import Account
import ArticlesDatabase

@MainActor final class SmartFeedEditorModel: ObservableObject {

	/// Which attribute a condition row matches on.
	enum ConditionField: String, CaseIterable, Identifiable {
		case status
		case starred
		case feed
		var id: String { rawValue }
	}

	/// An editable, UI-friendly representation of a single `SmartFeedCriteria.Condition`.
	struct EditableCondition: Identifiable {
		var id = UUID()
		var field: ConditionField = .status
		var statusIsRead = false        // false == "is Unread"
		var starredIsStarred = true     // true == "is Starred"
		var feedIsNegated = false       // false == "is"
		var feedChoiceID: String?       // matches FeedChoice.id
	}

	/// A selectable feed, across all active accounts.
	struct FeedChoice: Identifiable, Hashable {
		let accountID: String
		let feedID: String
		let name: String
		var id: String { "\(accountID)|\(feedID)" }
	}

	let existingID: String?
	let feedChoices: [FeedChoice]

	@Published var name: String
	@Published var matchType: SmartFeedCriteria.MatchType
	@Published var conditions: [EditableCondition]

	init(userSmartFeed: UserSmartFeed?) {
		self.feedChoices = Self.allFeedChoices()

		if let userSmartFeed {
			existingID = userSmartFeed.id
			name = userSmartFeed.name
			matchType = userSmartFeed.criteria.matchType
			conditions = userSmartFeed.criteria.conditions.map { Self.editableCondition(from: $0) }
		} else {
			existingID = nil
			name = ""
			matchType = .all
			conditions = [EditableCondition()]
		}

		if conditions.isEmpty {
			conditions = [EditableCondition()]
		}
	}

	var isEditingExisting: Bool {
		existingID != nil
	}

	var isValid: Bool {
		guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			return false
		}
		guard !conditions.isEmpty else {
			return false
		}
		// A feed condition with no feed chosen isn't usable.
		return conditions.allSatisfy { condition in
			condition.field != .feed || condition.feedChoiceID != nil
		}
	}

	func addCondition() {
		conditions.append(EditableCondition())
	}

	func removeCondition(_ condition: EditableCondition) {
		conditions.removeAll { $0.id == condition.id }
	}

	func save() {
		let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
		let criteria = SmartFeedCriteria(matchType: matchType, conditions: builtConditions())

		if let existingID {
			SmartFeedsController.shared.updateUserSmartFeed(UserSmartFeed(id: existingID, name: trimmedName, criteria: criteria))
		} else {
			SmartFeedsController.shared.addUserSmartFeed(UserSmartFeed(name: trimmedName, criteria: criteria))
		}
	}

	// MARK: - Private

	private func builtConditions() -> [SmartFeedCriteria.Condition] {
		conditions.compactMap { condition in
			switch condition.field {
			case .status:
				return .read(condition.statusIsRead)
			case .starred:
				return .starred(condition.starredIsStarred)
			case .feed:
				guard let choice = feedChoices.first(where: { $0.id == condition.feedChoiceID }) else {
					return nil
				}
				return .feed(accountID: choice.accountID, feedID: choice.feedID, isNegated: condition.feedIsNegated)
			}
		}
	}

	private static func editableCondition(from condition: SmartFeedCriteria.Condition) -> EditableCondition {
		switch condition {
		case .read(let isRead):
			return EditableCondition(field: .status, statusIsRead: isRead)
		case .starred(let isStarred):
			return EditableCondition(field: .starred, starredIsStarred: isStarred)
		case .feed(let accountID, let feedID, let isNegated):
			return EditableCondition(field: .feed, feedIsNegated: isNegated, feedChoiceID: "\(accountID)|\(feedID)")
		}
	}

	private static func allFeedChoices() -> [FeedChoice] {
		var choices = [FeedChoice]()
		for account in AccountManager.shared.activeAccounts {
			for feed in account.flattenedFeeds() {
				choices.append(FeedChoice(accountID: account.accountID, feedID: feed.feedID, name: feed.nameForDisplay))
			}
		}
		return choices.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
	}
}
