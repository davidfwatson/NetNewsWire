//
//  SmartFeedCriteria.swift
//  ArticlesDatabase
//
//  Defines the rules that back a user-created smart feed.
//

import Foundation

/// The set of rules for a user-created smart feed.
///
/// A smart feed matches an article when its conditions are satisfied according to
/// `matchType` (`all` = every condition, `any` = at least one). Lives in the
/// ArticlesDatabase module so both `FetchType` (in the Account module) and the SQL
/// builder here can reference it without a dependency cycle.
public struct SmartFeedCriteria: Codable, Sendable, Hashable {

	public enum MatchType: String, Codable, Sendable, Hashable {
		case all
		case any
	}

	public enum Condition: Codable, Sendable, Hashable {
		/// `true` == "is read", `false` == "is unread".
		case read(Bool)
		/// `true` == "is starred", `false` == "is not starred".
		case starred(Bool)
		/// A specific feed. `isNegated` == "is not". Feeds are account-scoped, so the
		/// `accountID` is stored alongside the `feedID` (which is only unique within an account).
		case feed(accountID: String, feedID: String, isNegated: Bool)
	}

	public var matchType: MatchType
	public var conditions: [Condition]

	public init(matchType: MatchType, conditions: [Condition]) {
		self.matchType = matchType
		self.conditions = conditions
	}

	/// A SQL WHERE fragment (and its bound parameters) evaluating these conditions
	/// against the `articles natural join statuses` query for a single account.
	///
	/// A feed condition that references a *different* account is reduced to a constant —
	/// false for "feed is", true for "feed is not" — because a feedID from another account
	/// can never match a row in this account's database. This keeps a cross-account smart
	/// feed correct when each account is queried in turn.
	public func whereClauseAndParameters(forAccountID accountID: String) -> (clause: String, parameters: [String]) {
		var fragments = [String]()
		var parameters = [String]()

		for condition in conditions {
			switch condition {
			case .read(let isRead):
				fragments.append("read=\(isRead ? 1 : 0)")
			case .starred(let isStarred):
				fragments.append("starred=\(isStarred ? 1 : 0)")
			case .feed(let conditionAccountID, let feedID, let isNegated):
				if conditionAccountID == accountID {
					fragments.append(isNegated ? "feedID<>?" : "feedID=?")
					parameters.append(feedID)
				} else {
					// Feed belongs to another account: "is" can never match here; "is not" always matches.
					fragments.append(isNegated ? "1" : "0")
				}
			}
		}

		if fragments.isEmpty {
			// No conditions: match-all matches everything, match-any matches nothing.
			return (matchType == .all ? "1" : "0", [])
		}

		let separator = matchType == .all ? " and " : " or "
		return (fragments.joined(separator: separator), parameters)
	}
}
