import Components
import EnvironmentModels
import Extensions
import Models
import OSLog
import Repositories
import SwiftUI

struct CategoryServingStyleAdminSheet: View {
    private let logger = Logger(category: "CategoryServingStyleAdminSheet")
    @Environment(Repository.self) private var repository
    @Environment(Router.self) private var router
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @Environment(\.dismiss) private var dismiss
    @State private var servingStyles: [ServingStyle]

    let category: Models.Category.JoinedSubcategoriesServingStyles

    init(category: Models.Category.JoinedSubcategoriesServingStyles) {
        self.category = category
        _servingStyles = State(wrappedValue: category.servingStyles)
    }

    var body: some View {
        List(servingStyles) { servingStyle in
            CategoryServingStyleRow(category: category, servingStyle: servingStyle, deleteServingStyle: deleteServingStyle)
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            RouterLink(
                "servingStyle.create.label",
                systemImage: "plus",
                open: .sheet(.servingStyleManagement(
                    pickedServingStyles: $servingStyles,
                    onSelect: { servingStyle in
                        await addServingStyleToCategory(servingStyle)
                    }
                ))
            )
            .bold()
        }
    }

    func addServingStyleToCategory(_ servingStyle: ServingStyle) async {
        do {
            try await repository.category.addServingStyle(categoryId: category.id, servingStyleId: servingStyle.id)
            withAnimation {
                servingStyles.append(servingStyle)
            }
        } catch {
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to add serving style to category'. Error: \(error) (\(#file):\(#line))")
        }
    }

    func deleteServingStyle(_ servingStyle: ServingStyle) async {
        do {
            try await repository.category.deleteServingStyle(categoryId: category.id, servingStyleId: servingStyle.id)
            withAnimation {
                servingStyles.remove(object: servingStyle)
            }
            feedbackEnvironmentModel.trigger(.notification(.success))
        } catch {
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to delete serving style '\(servingStyle.id)'. Error: \(error) (\(#file):\(#line))")
        }
    }
}

struct CategoryServingStyleRow: View {
    @State private var showDeleteServingStyleConfirmation = false

    let category: Models.Category.JoinedSubcategoriesServingStyles
    let servingStyle: ServingStyle
    let deleteServingStyle: (_ servingStyle: ServingStyle) async -> Void

    var body: some View {
        HStack {
            Text(servingStyle.label)
        }
        .swipeActions {
            Button(
                "labels.delete",
                systemImage: "trash",
                action: { showDeleteServingStyleConfirmation = true }
            )
            .tint(.red)
        }
        .confirmationDialog(
            "servingStyle.deleteWarning.title",
            isPresented: $showDeleteServingStyleConfirmation,
            titleVisibility: .visible,
            presenting: servingStyle
        ) { presenting in
            ProgressButton(
                "servingStyle.deleteWarning.label \(presenting.name) from \(category.name)",
                role: .destructive,
                action: {
                    await deleteServingStyle(presenting)
                }
            )
        }
    }
}
