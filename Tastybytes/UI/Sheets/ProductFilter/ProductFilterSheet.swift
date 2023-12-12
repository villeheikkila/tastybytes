import EnvironmentModels
import Models
import OSLog
import SwiftUI

struct ProductFilterSheet: View {
    enum Sections {
        case category, checkIns, sortBy
    }

    private let logger = Logger(category: "SeachFilterSheet")
    @Environment(AppDataEnvironmentModel.self) private var appDataEnvironmentModel
    @Environment(\.dismiss) private var dismiss
    @State private var categoryFilter: Models.Category.JoinedSubcategoriesServingStyles?
    @State private var subcategoryFilter: Subcategory?
    @State private var sortBy: Product.Filter.SortBy?
    @State private var onlyNonCheckedIn = false

    let sections: [Sections]
    let onApply: (_ filter: Product.Filter?) -> Void

    init(
        initialFilter: Product.Filter?,
        sections: [Sections],
        onApply: @escaping (_ filter: Product.Filter?) -> Void
    ) {
        self.sections = sections
        self.onApply = onApply

        subcategoryFilter = initialFilter?.subcategory
        categoryFilter = initialFilter?.category
        onlyNonCheckedIn = initialFilter?.onlyNonCheckedIn ?? false
        sortBy = initialFilter?.sortBy
    }

    var body: some View {
        Form {
            if sections.contains(.category) {
                Section("Category") {
                    Picker(selection: $categoryFilter) {
                        Text("Select All").tag(Models.Category.JoinedSubcategoriesServingStyles?(nil))
                        ForEach(appDataEnvironmentModel.categories) { category in
                            Text(category.name).tag(Optional(category))
                        }
                    } label: {
                        Text("Category")
                    }
                    Picker(selection: $subcategoryFilter) {
                        Text("Select All").tag(Subcategory?(nil))
                        if let categoryFilter {
                            ForEach(categoryFilter.subcategories) { subcategory in
                                Text(subcategory.name).tag(Optional(subcategory))
                            }
                        }
                    } label: {
                        Text("Subcategory")
                    }.disabled(categoryFilter == nil)
                }
            }

            if sections.contains(.checkIns) {
                Section("Check-ins") {
                    Toggle("Only things I have not had", isOn: $onlyNonCheckedIn)
                }
            }
            if sections.contains(.sortBy) {
                Section("Sort By") {
                    Picker(selection: $sortBy) {
                        Text("None").tag(Product.Filter.SortBy?(nil))
                        ForEach(Product.Filter.SortBy.allCases) { sortBy in
                            Text(sortBy.label).tag(Optional(sortBy))
                        }
                    } label: {
                        Text("Rating")
                    }
                }
            }
            Button("Reset", action: { resetFilter() }).bold()
        }
        .scrollDisabled(true)
        .navigationTitle("Filter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .cancellationAction) {
            Button("Cancel", role: .cancel, action: { dismiss() })
        }
        ToolbarItemGroup(placement: .confirmationAction) {
            Button("Apply", action: {
                onApply(getFilter())
                dismiss()
            }).bold()
        }
    }

    func getFilter() -> Product.Filter? {
        guard !(categoryFilter == nil && subcategoryFilter == nil && onlyNonCheckedIn == false && sortBy == nil)
        else { return nil }
        return Product.Filter(
            category: categoryFilter,
            subcategory: subcategoryFilter,
            onlyNonCheckedIn: onlyNonCheckedIn,
            sortBy: sortBy
        )
    }

    func resetFilter() {
        withAnimation {
            categoryFilter = nil
            subcategoryFilter = nil
            onlyNonCheckedIn = false
            categoryFilter = nil
            sortBy = nil
        }
    }
}
