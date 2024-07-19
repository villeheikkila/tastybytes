import Components
import EnvironmentModels
import Models
import OSLog
import Repositories
import SwiftUI

struct ProductEditSuggestionScreen: View {
    @Binding var product: Product.Detailed?

    var editSuggestions: [Product.EditSuggestion] {
        product?.editSuggestions ?? []
    }

    var body: some View {
        List(editSuggestions) { editSuggestion in
            ProductEditSuggestionRowView(product: $product, editSuggestion: editSuggestion)
        }
        .listStyle(.plain)
        .overlay {
            if editSuggestions.isEmpty {
                ContentUnavailableView("admin.noEditSuggestions.title", systemImage: "tray")
            }
        }
        .navigationTitle("product.admin.editSuggestion.navigationTitle")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProductEditSuggestionRowView: View {
    private let logger = Logger(category: "CompanyEditSuggestionRow")
    @Environment(Repository.self) private var repository
    @Environment(Router.self) private var router
    @State private var showApplyConfirmationDialog = false
    @State private var showDeleteConfirmationDialog = false
    @Binding var product: Product.Detailed?
    let editSuggestion: Product.EditSuggestion

    var body: some View {
        ProductEditSuggestionEntityView(editSuggestion: editSuggestion)
            .padding(.vertical, 2)
            .swipeActions {
                Button("admin.editSuggestion.delete.label", systemImage: "trash") {
                    showDeleteConfirmationDialog = true
                }
                .tint(.red)
                Button("admin.editSuggestion.apply.label", systemImage: "checkmark") {
                    showApplyConfirmationDialog = true
                }
                .tint(.green)
            }
            .confirmationDialog(
                "admin.editSuggestion.apply.description",
                isPresented: $showApplyConfirmationDialog,
                titleVisibility: .visible,
                presenting: editSuggestion
            ) { presenting in
                AsyncButton(
                    "admin.editSuggestion.apply.label \(product?.name ?? "-") \(presenting.name ?? "-")",
                    action: {
                        await resolveEditSuggestion(presenting)
                    }
                )
                .tint(.green)
            }
            .confirmationDialog(
                "admin.editSuggestion.delete.description",
                isPresented: $showDeleteConfirmationDialog,
                titleVisibility: .visible,
                presenting: editSuggestion
            ) { presenting in
                AsyncButton(
                    "admin.editSuggestion.delete.label \(presenting.name ?? "-")",
                    action: {
                        await deleteEditSuggestion(presenting)
                    }
                )
                .tint(.green)
            }
            .listRowBackground(Color.clear)
    }

    private func deleteEditSuggestion(_ editSuggestion: Product.EditSuggestion) async {
        guard let product else { return }
        do {
            try await repository.product.deleteEditSuggestion(editSuggestion: editSuggestion)
            withAnimation {
                self.product = product.copyWith(editSuggestions: product.editSuggestions.removing(editSuggestion))
            }
        } catch {
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to delete product edit suggestions '\(product.id)'. Error: \(error) (\(#file):\(#line))")
        }
    }

    private func resolveEditSuggestion(_ editSuggestion: Product.EditSuggestion) async {
        guard let product else { return }
        do {
            try await repository.product.resolveEditSuggestion(editSuggestion: editSuggestion)
            withAnimation {
                self.product = product.copyWith(name: editSuggestion.name, editSuggestions: product.editSuggestions.replacing(editSuggestion, with: editSuggestion.copyWith(resolvedAt: Date.now)))
            }
            router.removeLast()
        } catch {
            guard !error.isCancelled else { return }
            router.open(.alert(.init()))
            logger.error("Failed to delete edit suggestion '\(product.id)'. Error: \(error) (\(#file):\(#line))")
        }
    }
}

struct ProductEditSuggestionEntityView: View {
    let editSuggestion: Product.EditSuggestion

    var body: some View {
        Text(editSuggestion.id.formatted())
    }
}
