//
//  SmartFeedEditorView.swift
//  NetNewsWire
//
//  Shared SwiftUI editor for creating and editing custom smart feeds.
//  Hosted in a UIHostingController on iOS and an NSHostingController on Mac.
//

import SwiftUI
import ArticlesDatabase

struct SmartFeedEditorView: View {

	@StateObject private var model: SmartFeedEditorModel
	private let onDismiss: () -> Void

	init(userSmartFeed: UserSmartFeed?, onDismiss: @escaping () -> Void) {
		_model = StateObject(wrappedValue: SmartFeedEditorModel(userSmartFeed: userSmartFeed))
		self.onDismiss = onDismiss
	}

	var body: some View {
		VStack(spacing: 0) {
			Form {
				Section {
					TextField(SmartFeedEditorView.namePrompt, text: $model.name)
				}

				Section(header: Text(SmartFeedEditorView.conditionsHeader)) {
					Picker(selection: $model.matchType) {
						Text(SmartFeedEditorView.matchAll).tag(SmartFeedCriteria.MatchType.all)
						Text(SmartFeedEditorView.matchAny).tag(SmartFeedCriteria.MatchType.any)
					} label: {
						Text(SmartFeedEditorView.matchLabel)
					}

					ForEach($model.conditions) { $condition in
						ConditionRow(condition: $condition, feedChoices: model.feedChoices) {
							model.removeCondition(condition)
						}
					}

					Button {
						model.addCondition()
					} label: {
						Label(SmartFeedEditorView.addCondition, systemImage: "plus.circle")
					}
				}
			}

			Divider()

			HStack {
				Button(SmartFeedEditorView.cancel, role: .cancel) {
					onDismiss()
				}
				.keyboardShortcut(.cancelAction)

				Spacer()

				Button(model.isEditingExisting ? SmartFeedEditorView.save : SmartFeedEditorView.add) {
					model.save()
					onDismiss()
				}
				.keyboardShortcut(.defaultAction)
				.disabled(!model.isValid)
			}
			.padding()
		}
		.frame(minWidth: 460, minHeight: 380)
	}
}

private struct ConditionRow: View {

	@Binding var condition: SmartFeedEditorModel.EditableCondition
	let feedChoices: [SmartFeedEditorModel.FeedChoice]
	let onRemove: () -> Void

	var body: some View {
		HStack {
			Picker(selection: $condition.field) {
				Text(SmartFeedEditorView.fieldStatus).tag(SmartFeedEditorModel.ConditionField.status)
				Text(SmartFeedEditorView.fieldStarred).tag(SmartFeedEditorModel.ConditionField.starred)
				Text(SmartFeedEditorView.fieldFeed).tag(SmartFeedEditorModel.ConditionField.feed)
			} label: {
				EmptyView()
			}
			.labelsHidden()
			.fixedSize()

			valueControls

			Spacer()

			Button(role: .destructive) {
				onRemove()
			} label: {
				Image(systemName: "minus.circle")
			}
			.buttonStyle(.borderless)
			.accessibilityLabel(Text(SmartFeedEditorView.removeCondition))
		}
	}

	@ViewBuilder
	private var valueControls: some View {
		switch condition.field {
		case .status:
			Picker(selection: $condition.statusIsRead) {
				Text(SmartFeedEditorView.statusUnread).tag(false)
				Text(SmartFeedEditorView.statusRead).tag(true)
			} label: {
				EmptyView()
			}
			.labelsHidden()
			.fixedSize()

		case .starred:
			Picker(selection: $condition.starredIsStarred) {
				Text(SmartFeedEditorView.starredYes).tag(true)
				Text(SmartFeedEditorView.starredNo).tag(false)
			} label: {
				EmptyView()
			}
			.labelsHidden()
			.fixedSize()

		case .feed:
			Picker(selection: $condition.feedIsNegated) {
				Text(SmartFeedEditorView.feedIs).tag(false)
				Text(SmartFeedEditorView.feedIsNot).tag(true)
			} label: {
				EmptyView()
			}
			.labelsHidden()
			.fixedSize()

			Picker(selection: $condition.feedChoiceID) {
				Text(SmartFeedEditorView.feedSelect).tag(String?.none)
				ForEach(feedChoices) { choice in
					Text(choice.name).tag(Optional(choice.id))
				}
			} label: {
				EmptyView()
			}
			.labelsHidden()
		}
	}
}

// MARK: - Localized strings

extension SmartFeedEditorView {
	static let namePrompt = NSLocalizedString("Name", comment: "Smart feed name field")
	static let conditionsHeader = NSLocalizedString("Conditions", comment: "Smart feed conditions section header")
	static let matchLabel = NSLocalizedString("Match", comment: "Smart feed match label")
	static let matchAll = NSLocalizedString("all", comment: "Match all conditions")
	static let matchAny = NSLocalizedString("any", comment: "Match any condition")
	static let addCondition = NSLocalizedString("Add Condition", comment: "Add a smart feed condition")
	static let removeCondition = NSLocalizedString("Remove Condition", comment: "Remove a smart feed condition")
	static let cancel = NSLocalizedString("Cancel", comment: "Cancel")
	static let save = NSLocalizedString("Save", comment: "Save")
	static let add = NSLocalizedString("Add", comment: "Add")
	static let fieldStatus = NSLocalizedString("Status", comment: "Condition field: read status")
	static let fieldStarred = NSLocalizedString("Starred", comment: "Condition field: starred status")
	static let fieldFeed = NSLocalizedString("Feed", comment: "Condition field: feed")
	static let statusUnread = NSLocalizedString("is Unread", comment: "Status condition value")
	static let statusRead = NSLocalizedString("is Read", comment: "Status condition value")
	static let starredYes = NSLocalizedString("is Starred", comment: "Starred condition value")
	static let starredNo = NSLocalizedString("is Not Starred", comment: "Starred condition value")
	static let feedIs = NSLocalizedString("is", comment: "Feed condition operator")
	static let feedIsNot = NSLocalizedString("is not", comment: "Feed condition operator")
	static let feedSelect = NSLocalizedString("Select…", comment: "Feed condition: no feed chosen")
}
