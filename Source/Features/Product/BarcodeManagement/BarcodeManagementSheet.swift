import Components
import EnvironmentModels
import Extensions
import Models
import OSLog
import Repositories
import SwiftUI

struct BarcodeManagementSheet: View {
    private let logger = Logger(category: "BarcodeManagementSheet")
    @Environment(Repository.self) private var repository
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @Environment(\.dismiss) private var dismiss
    @State private var barcodes: [ProductBarcode.JoinedWithCreator] = []
    @State private var isInitialized = false
    @State private var alertError: AlertError?

    let product: Product.Joined

    var body: some View {
        List(barcodes) { barcode in
            BarcodeManagementRow(barcode: barcode)
                .swipeActions {
                    ProgressButton("Delete", systemImage: "trash.fill", role: .destructive, action: {
                        await deleteBarcode(barcode)
                        feedbackEnvironmentModel.trigger(.notification(.success))
                    })
                }
                .contextMenu {
                    ProgressButton("Delete", systemImage: "trash.fill", role: .destructive, action: {
                        await deleteBarcode(barcode)
                        feedbackEnvironmentModel.trigger(.notification(.success))
                    })
                }
        }
        .listStyle(.plain)
        .background {
            if isInitialized, barcodes.isEmpty {
                BarcodeManagementContentUnavailable()
            }
        }
        .task {
            await getBarcodes()
        }
        .alertError($alertError)
        .navigationTitle("Barcode Management")
        .toolbar {
            toolbarContent
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarDismissAction()
    }

    func deleteBarcode(_ barcode: ProductBarcode.JoinedWithCreator) async {
        switch await repository.productBarcode.delete(id: barcode.id) {
        case .success:
            withAnimation {
                barcodes.remove(object: barcode)
            }
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Failed to fetch barcodes for product. Error: \(error) (\(#file):\(#line))")
        }
    }

    func getBarcodes() async {
        switch await repository.productBarcode.getByProductId(id: product.id) {
        case let .success(barcodes):
            withAnimation {
                isInitialized = true
                self.barcodes = barcodes
            }
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Failed to fetch barcodes for product. Error: \(error) (\(#file):\(#line))")
        }
    }
}
