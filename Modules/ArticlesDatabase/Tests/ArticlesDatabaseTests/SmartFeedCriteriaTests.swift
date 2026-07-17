//
//  SmartFeedCriteriaTests.swift
//  ArticlesDatabaseTests
//
//  Verifies the SQL WHERE-clause building for custom smart feeds, including the
//  cross-account feed-scoping rules.
//

import XCTest
@testable import ArticlesDatabase

final class SmartFeedCriteriaTests: XCTestCase {

	private let accountID = "account-1"
	private let otherAccountID = "account-2"

	// MARK: - Single conditions

	func testUnread() {
		let criteria = SmartFeedCriteria(matchType: .all, conditions: [.read(false)])
		let (clause, parameters) = criteria.whereClauseAndParameters(forAccountID: accountID)
		XCTAssertEqual(clause, "read=0")
		XCTAssertTrue(parameters.isEmpty)
	}

	func testRead() {
		let criteria = SmartFeedCriteria(matchType: .all, conditions: [.read(true)])
		XCTAssertEqual(criteria.whereClauseAndParameters(forAccountID: accountID).clause, "read=1")
	}

	func testStarred() {
		let starred = SmartFeedCriteria(matchType: .all, conditions: [.starred(true)])
		XCTAssertEqual(starred.whereClauseAndParameters(forAccountID: accountID).clause, "starred=1")

		let notStarred = SmartFeedCriteria(matchType: .all, conditions: [.starred(false)])
		XCTAssertEqual(notStarred.whereClauseAndParameters(forAccountID: accountID).clause, "starred=0")
	}

	// MARK: - Feed conditions (same account)

	func testFeedIsSameAccount() {
		let criteria = SmartFeedCriteria(matchType: .all, conditions: [.feed(accountID: accountID, feedID: "feed-1", isNegated: false)])
		let (clause, parameters) = criteria.whereClauseAndParameters(forAccountID: accountID)
		XCTAssertEqual(clause, "feedID=?")
		XCTAssertEqual(parameters, ["feed-1"])
	}

	func testFeedIsNotSameAccount() {
		let criteria = SmartFeedCriteria(matchType: .all, conditions: [.feed(accountID: accountID, feedID: "feed-1", isNegated: true)])
		let (clause, parameters) = criteria.whereClauseAndParameters(forAccountID: accountID)
		XCTAssertEqual(clause, "feedID<>?")
		XCTAssertEqual(parameters, ["feed-1"])
	}

	// MARK: - Feed conditions (different account) reduce to constants

	func testFeedIsOtherAccountIsFalse() {
		// "feed is X" where X lives in another account can never match here.
		let criteria = SmartFeedCriteria(matchType: .all, conditions: [.feed(accountID: otherAccountID, feedID: "feed-1", isNegated: false)])
		let (clause, parameters) = criteria.whereClauseAndParameters(forAccountID: accountID)
		XCTAssertEqual(clause, "0")
		XCTAssertTrue(parameters.isEmpty)
	}

	func testFeedIsNotOtherAccountIsTrue() {
		// "feed is not X" where X lives in another account is always true here.
		let criteria = SmartFeedCriteria(matchType: .all, conditions: [.feed(accountID: otherAccountID, feedID: "feed-1", isNegated: true)])
		let (clause, parameters) = criteria.whereClauseAndParameters(forAccountID: accountID)
		XCTAssertEqual(clause, "1")
		XCTAssertTrue(parameters.isEmpty)
	}

	// MARK: - Combining conditions

	func testMatchAllJoinsWithAnd() {
		let criteria = SmartFeedCriteria(matchType: .all, conditions: [.read(false), .starred(true)])
		XCTAssertEqual(criteria.whereClauseAndParameters(forAccountID: accountID).clause, "read=0 and starred=1")
	}

	func testMatchAnyJoinsWithOr() {
		let criteria = SmartFeedCriteria(matchType: .any, conditions: [.read(false), .starred(true)])
		XCTAssertEqual(criteria.whereClauseAndParameters(forAccountID: accountID).clause, "read=0 or starred=1")
	}

	/// The motivating example: all unread except specific feeds.
	func testUnreadExcludingFeeds() {
		let criteria = SmartFeedCriteria(matchType: .all, conditions: [
			.read(false),
			.feed(accountID: accountID, feedID: "noisy-1", isNegated: true),
			.feed(accountID: accountID, feedID: "noisy-2", isNegated: true)
		])
		let (clause, parameters) = criteria.whereClauseAndParameters(forAccountID: accountID)
		XCTAssertEqual(clause, "read=0 and feedID<>? and feedID<>?")
		XCTAssertEqual(parameters, ["noisy-1", "noisy-2"])
	}

	/// Parameter order must follow condition order so placeholders bind correctly.
	func testParameterOrderMatchesConditionOrder() {
		let criteria = SmartFeedCriteria(matchType: .all, conditions: [
			.feed(accountID: accountID, feedID: "first", isNegated: false),
			.feed(accountID: accountID, feedID: "second", isNegated: true)
		])
		XCTAssertEqual(criteria.whereClauseAndParameters(forAccountID: accountID).parameters, ["first", "second"])
	}

	// MARK: - Empty conditions

	func testEmptyMatchAllIsTrue() {
		let criteria = SmartFeedCriteria(matchType: .all, conditions: [])
		XCTAssertEqual(criteria.whereClauseAndParameters(forAccountID: accountID).clause, "1")
	}

	func testEmptyMatchAnyIsFalse() {
		let criteria = SmartFeedCriteria(matchType: .any, conditions: [])
		XCTAssertEqual(criteria.whereClauseAndParameters(forAccountID: accountID).clause, "0")
	}

	// MARK: - Round-trip Codable

	func testCodableRoundTrip() throws {
		let criteria = SmartFeedCriteria(matchType: .any, conditions: [
			.read(false),
			.starred(true),
			.feed(accountID: accountID, feedID: "feed-1", isNegated: true)
		])
		let data = try JSONEncoder().encode(criteria)
		let decoded = try JSONDecoder().decode(SmartFeedCriteria.self, from: data)
		XCTAssertEqual(criteria, decoded)
	}
}
