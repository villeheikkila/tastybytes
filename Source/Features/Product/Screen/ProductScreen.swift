import Components
import EnvironmentModels
import Extensions
import Models
import OSLog
import Repositories
import SwiftUI

@MainActor
struct ProductScreen: View {
    private let logger = Logger(category: "ProductScreen")
    @Environment(Repository.self) private var repository
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @Environment(Router.self) private var router
    @State private var product: Product.Joined
    @State private var summary: Summary?
    @State private var showDeleteProductConfirmationDialog = false
    @State private var showUnverifyProductConfirmation = false
    @State private var resetView: Int = 0

    @State private var loadedWithBarcode: Barcode?
    @State private var alertError: AlertError?

    // check-in images
    @State private var checkInImages = [ImageEntity.JoinedCheckIn]()
    @State private var isLoadingCheckInImages = false
    @State private var checkInImagesPage = 0

    // state
    @State private var refreshId = 0
    @State private var resultId: Int?
    @State private var checkInImageTask: Task<Void, Never>?
    @State private var sheet: Sheet?

    // wishlist
    @State private var isOnWishlist = false

    init(product: Product.Joined, loadedWithBarcode: Barcode? = nil) {
        _product = State(wrappedValue: product)
        _loadedWithBarcode = State(wrappedValue: loadedWithBarcode)
    }

    var body: some View {
        CheckInList(
            id: "ProductScreen",
            fetcher: .product(product),
            onRefresh: {
                refreshId += 1
            },
            header: {
                header
            }
        )
        .safeAreaInset(edge: .top, alignment: .trailing) {
            if loadedWithBarcode != nil {
                ProductScreenLoadedFromBarcodeOverlay(loadedWithBarcode: $loadedWithBarcode)
            }
        }
        .id(resetView)
        .onDisappear {
            checkInImageTask?.cancel()
        }
        .task(id: refreshId) { [refreshId] in
            guard refreshId != resultId else { return }
            logger.info("Refreshing product screen with id: \(refreshId)")
            await getProductData()
            resultId = refreshId
        }
        .toolbar {
            toolbarContent
        }
        .alertError($alertError)
        .confirmationDialog("product.unverify.confirmation.description",
                            isPresented: $showUnverifyProductConfirmation,
                            presenting: product)
        { presenting in
            ProgressButton("product.unverify.confirmation.label \(presenting.name)", role: .destructive, action: {
                await verifyProduct(product: presenting, isVerified: false)
            })
        }
        .confirmationDialog("product.delete.confirmation.description",
                            isPresented: $showDeleteProductConfirmationDialog,
                            titleVisibility: .visible,
                            presenting: product)
        { presenting in
            ProgressButton(
                "product.delete.confirmation.label \(presenting.formatted(.fullName))",
                role: .destructive,
                action: { await deleteProduct(presenting) }
            )
        }
    }

    @ViewBuilder private var header: some View {
        ProductScreenHeader(
            product: product,
            summary: summary,
            checkInImages: checkInImages,
            loadMoreImages: {
                checkInImageTask = Task {
                    defer { checkInImageTask = nil }
                    await fetchImages(reset: false)
                }
            },
            onRefreshCheckIns: refreshCheckIns,
            isOnWishlist: $isOnWishlist
        )
        .sheets(item: $sheet)
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            ProductShareLinkView(product: product)
            Menu {
                ControlGroup {
                    Button("checkIn.create.label", systemImage: "plus", action: { sheet = .newCheckIn(product, onCreation: { _ in
                        refreshCheckIns()
                    }) })
                    .disabled(!profileEnvironmentModel.hasPermission(.canCreateCheckIns))
                    ProductShareLinkView(product: product)
                    if profileEnvironmentModel.hasPermission(.canAddBarcodes) {
                        Button(
                            "labels.add",
                            systemImage: "barcode.viewfinder",
                            action: { sheet = .barcodeScanner(onComplete: { barcode in
                                Task { await addBarcodeToProduct(barcode) }
                            }) }
                        )
                    }
                }
                VerificationButton(isVerified: product.isVerified, verify: {
                    await verifyProduct(product: product, isVerified: true)
                }, unverify: {
                    showUnverifyProductConfirmation = true
                })
                Divider()
                RouterLink("product.screen.open", systemImage: "grid", screen: .product(product))
                RouterLink(
                    "subBrand.screen.open",
                    systemImage: "cart",
                    screen: .fetchSubBrand(product.subBrand)
                )
                RouterLink("brand.screen.open", systemImage: "cart", screen: .fetchBrand(product.subBrand.brand))
                RouterLink(
                    "company.screen.open",
                    systemImage: "network",
                    screen: .company(product.subBrand.brand.brandOwner)
                )
                Divider()
                if profileEnvironmentModel.hasPermission(.canEditCompanies) {
                    Button("labels.edit", systemImage: "pencil", action: { sheet = .productEdit(product: product, onEdit: {
                        refreshId += 1
                    }) })
                } else {
                    Button(
                        "product.editSuggestion.label",
                        systemImage: "pencil",
                        action: { sheet = .productEditSuggestion(product: product) }
                    )
                }

                Button(action: { sheet = .duplicateProduct(
                    mode: profileEnvironmentModel.hasPermission(.canMergeProducts) ? .mergeDuplicate : .reportDuplicate,
                    product: product
                ) }, label: {
                    if profileEnvironmentModel.hasPermission(.canMergeProducts) {
                        Label("product.mergeTo.label", systemImage: "doc.on.doc")
                    } else {
                        Label("product.markAsDuplicate.label", systemImage: "doc.on.doc")
                    }
                })

                Menu {
                    if profileEnvironmentModel.hasPermission(.canDeleteBarcodes) {
                        Button("barcode.management.open", systemImage: "barcode", action: { sheet = .barcodeManagement(product: product) })
                    }

                    if profileEnvironmentModel.hasPermission(.canDeleteProducts) {
                        Button(
                            "labels.delete",
                            systemImage: "trash.fill",
                            role: .destructive,
                            action: { showDeleteProductConfirmationDialog = true }
                        )
                        .disabled(product.isVerified)
                    }
                } label: {
                    Label("admin.menuSection.title", systemImage: "gear")
                        .labelStyle(.iconOnly)
                }

                ReportButton(sheet: $sheet, entity: .product(product))
            } label: {
                Label("labels.menu", systemImage: "ellipsis")
                    .labelStyle(.iconOnly)
            }
        }
    }

    func getProductData() async {
        async let productPromise = repository.product.getById(id: product.id)
        async let summaryPromise = repository.product.getSummaryById(id: product.id)
        async let wishlistPromise = repository.product.checkIfOnWishlist(id: product.id)
        async let fetchImagePromise: Void = fetchImages(reset: true)

        let (productResult, summaryResult, wishlistResult, _) = await (
            productPromise,
            summaryPromise,
            wishlistPromise,
            fetchImagePromise
        )

        switch productResult {
        case let .success(refreshedProduct):
            withAnimation {
                product = refreshedProduct
            }
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Failed to refresh product by id. Error: \(error) (\(#file):\(#line))")
        }

        switch summaryResult {
        case let .success(summary):
            self.summary = summary
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Failed to load product summary. Error: \(error) (\(#file):\(#line))")
        }

        switch wishlistResult {
        case let .success(isOnWishlist):
            withAnimation {
                self.isOnWishlist = isOnWishlist
            }
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Failed to load wishlist status. Error: \(error) (\(#file):\(#line))")
        }
        logger.info("Refreshing product page completed, refresh id: \(refreshId)")
    }

    func refreshCheckIns() {
        resetView += 1
        refreshId += 1
    }

    func verifyProduct(product: Product.Joined, isVerified: Bool) async {
        switch await repository.product.verification(id: product.id, isVerified: isVerified) {
        case .success:
            feedbackEnvironmentModel.trigger(.notification(.success))
            refreshId += 1
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Failed to verify product. Error: \(error) (\(#file):\(#line))")
        }
    }

    @MainActor
    func deleteProduct(_ product: Product.Joined) async {
        switch await repository.product.delete(id: product.id) {
        case .success:
            feedbackEnvironmentModel.trigger(.notification(.success))
            router.removeLast()
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Failed to delete product. Error: \(error) (\(#file):\(#line))")
        }
    }

    func addBarcodeToProduct(_ barcode: Barcode) async {
        switch await repository.productBarcode.addToProduct(product: product, barcode: barcode) {
        case .success:
            feedbackEnvironmentModel.toggle(.success("bracode.add.success.toast"))
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Adding barcode \(barcode.barcode) to product failed. Error: \(error) (\(#file):\(#line))")
        }
    }

    func fetchImages(reset: Bool) async {
        if reset {
            withAnimation {
                checkInImageTask?.cancel()
                checkInImages = []
                isLoadingCheckInImages = false
                checkInImagesPage = 0
            }
        }
        guard !isLoadingCheckInImages else { return }
        let (from, to) = getPagination(page: checkInImagesPage, size: 10)
        isLoadingCheckInImages = true

        switch await repository.checkIn.getCheckInImages(by: .product(product), from: from, to: to) {
        case let .success(checkIns):
            withAnimation {
                checkInImages.append(contentsOf: checkIns)
            }
            checkInImagesPage += 1
            isLoadingCheckInImages = false
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Fetching check-in images failed. Description: \(error.localizedDescription). Error: \(error) (\(#file):\(#line))")
        }
    }
}
