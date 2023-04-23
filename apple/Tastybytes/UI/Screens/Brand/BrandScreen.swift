import CachedAsyncImage
import SwiftUI

struct BrandScreen: View {
  private let logger = getLogger(category: "BrandScreen")
  @EnvironmentObject private var repository: Repository
  @EnvironmentObject private var profileManager: ProfileManager
  @EnvironmentObject private var feedbackManager: FeedbackManager
  @EnvironmentObject private var router: Router
  @State private var brand: Brand.JoinedSubBrandsProductsCompany
  @State private var summary: Summary?
  @State private var editBrand: Brand.JoinedSubBrandsProductsCompany?
  @State private var toUnverifySubBrand: SubBrand.JoinedProduct? {
    didSet {
      showSubBrandUnverificationConfirmation = true
    }
  }

  @State private var showSubBrandUnverificationConfirmation = false
  @State private var showBrandUnverificationConfirmation = false
  @State private var showDeleteProductConfirmationDialog = false
  @State private var productToDelete: Product.JoinedCategory? {
    didSet {
      if productToDelete != nil {
        showDeleteProductConfirmationDialog = true
      }
    }
  }

  @State private var showDeleteBrandConfirmationDialog = false
  @State private var brandToDelete: Brand.JoinedSubBrandsProducts? {
    didSet {
      showDeleteBrandConfirmationDialog = true
    }
  }

  @State private var showDeleteSubBrandConfirmation = false
  @State private var toDeleteSubBrand: SubBrand.JoinedProduct? {
    didSet {
      if oldValue == nil {
        showDeleteSubBrandConfirmation = true
      } else {
        showDeleteSubBrandConfirmation = false
      }
    }
  }

  let refreshOnLoad: Bool

  init(brand: Brand.JoinedSubBrandsProductsCompany, refreshOnLoad: Bool? = false) {
    _brand = State(wrappedValue: brand)
    self.refreshOnLoad = refreshOnLoad ?? false
  }

  var sortedSubBrands: [SubBrand.JoinedProduct] {
    brand.subBrands
      .filter { !($0.name == nil && $0.products.isEmpty) }
      .sorted()
  }

  var body: some View {
    List {
      if let summary, summary.averageRating != nil {
        Section {
          SummaryView(summary: summary)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
      ForEach(sortedSubBrands) { subBrand in
        Section {
          ForEach(subBrand.products) { product in
            let productJoined = Product.Joined(
              product: product,
              subBrand: subBrand,
              brand: brand
            )
            RouterLink(screen: .product(productJoined)) {
              ProductItemView(product: productJoined)
                .padding(2)
                .contextMenu {
                  RouterLink(sheet: .duplicateProduct(
                    mode: profileManager.hasPermission(.canMergeProducts) ? .mergeDuplicate : .reportDuplicate,
                    product: productJoined
                  ), label: {
                    if profileManager.hasPermission(.canMergeProducts) {
                      Label("Merge to...", systemImage: "doc.on.doc")
                    } else {
                      Label("Mark as duplicate", systemImage: "doc.on.doc")
                    }
                  })

                  if profileManager.hasPermission(.canDeleteProducts) {
                    Button(
                      "Delete",
                      systemImage: "trash.fill",
                      role: .destructive,
                      action: { productToDelete = product }
                    ).foregroundColor(.red)
                      .disabled(product.isVerified)
                  }
                }
            }
          }
        } header: {
          HStack {
            if let name = subBrand.name {
              Text(name)
            }
            Spacer()
            Menu {
              VerificationButton(isVerified: subBrand.isVerified, verify: {
                await verifySubBrand(subBrand, isVerified: true)
              }, unverify: {
                toUnverifySubBrand = subBrand
              })
              Divider()
              if profileManager.hasPermission(.canEditBrands) {
                RouterLink(
                  "Edit",
                  systemImage: "pencil",
                  sheet: .editSubBrand(brand: brand, subBrand: subBrand, onUpdate: {
                    await refresh()
                  })
                )
              }
              ReportButton(entity: .subBrand(brand, subBrand))
              if profileManager.hasPermission(.canDeleteBrands) {
                Button("Delete", systemImage: "trash.fill", role: .destructive, action: { toDeleteSubBrand = subBrand })
                  .disabled(subBrand.isVerified)
              }
            } label: {
              Label("Options menu", systemImage: "ellipsis")
                .labelStyle(.iconOnly)
                .frame(width: 24, height: 24)
            }
          }
        }
        .headerProminence(.increased)
      }
    }
    .listStyle(.plain)
    .refreshable {
      await feedbackManager.wrapWithHaptics {
        await refresh()
      }
    }
    .task {
      if summary == nil {
        await getSummary()
      }
      if refreshOnLoad {
        await refresh()
      }
    }
    .toolbar {
      toolbarContent
    }
    .confirmationDialog("Unverify Sub-brand",
                        isPresented: $showSubBrandUnverificationConfirmation,
                        presenting: toUnverifySubBrand)
    { presenting in
      ProgressButton("Unverify \(presenting.name ?? "default") sub-brand", action: {
        await verifySubBrand(presenting, isVerified: false)
      })
    }
    .confirmationDialog("Unverify Brand",
                        isPresented: $showBrandUnverificationConfirmation,
                        presenting: brand)
    { presenting in
      ProgressButton("Unverify \(presenting.name) brand", action: {
        await verifyBrand(brand: presenting, isVerified: false)
      })
    }
    .confirmationDialog("Are you sure you want to delete sub-brand and all related products?",
                        isPresented: $showDeleteSubBrandConfirmation,
                        titleVisibility: .visible,
                        presenting: toDeleteSubBrand)
    { presenting in
      ProgressButton(
        "Delete \(presenting.name ?? "default sub-brand")",
        role: .destructive,
        action: {
          await deleteSubBrand(presenting)
        }
      )
    }
    .confirmationDialog("Are you sure you want to delete brand and all related sub-brands and products?",
                        isPresented: $showDeleteBrandConfirmationDialog,
                        titleVisibility: .visible,
                        presenting: brand)
    { presenting in
      ProgressButton("Delete \(presenting.name)", role: .destructive, action: {
        await deleteBrand(presenting)
      })
    }
  }

  @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      HStack(alignment: .center, spacing: 18) {
        if let logoUrl = brand.logoUrl {
          CachedAsyncImage(url: logoUrl, urlCache: .imageCache) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 32, height: 32)
              .accessibility(hidden: true)
          } placeholder: {
            ProgressView()
          }
        }
        Text(brand.name)
          .font(.headline)
      }
    }
    ToolbarItem(placement: .navigationBarTrailing) {
      navigationBarMenu
    }
  }

  private var navigationBarMenu: some View {
    Menu {
      VerificationButton(isVerified: brand.isVerified, verify: {
        await verifyBrand(brand: brand, isVerified: true)
      }, unverify: {
        showBrandUnverificationConfirmation = true
      })
      Divider()
      ShareLink("Share", item: NavigatablePath.brand(id: brand.id).url)
      if profileManager.hasPermission(.canCreateProducts) {
        RouterLink("Add Product", systemImage: "plus", sheet: .addProductToBrand(brand: brand, onCreate: { product in
          router.navigate(screen: .product(product))
        }))
      }
      Divider()
      if profileManager.hasPermission(.canEditBrands) {
        RouterLink("Edit", systemImage: "pencil", sheet: .editBrand(brand: brand, onUpdate: {
          await refresh()
        }))
      }
      ReportButton(entity: .brand(brand))
      if profileManager.hasPermission(.canDeleteBrands) {
        Button(
          "Delete",
          systemImage: "trash.fill",
          role: .destructive,
          action: { showDeleteBrandConfirmationDialog = true }
        )
        .disabled(brand.isVerified)
      }
    } label: {
      Label("Options menu", systemImage: "ellipsis")
        .labelStyle(.iconOnly)
    }
  }

  func refresh() async {
    let brandId = brand.id
    async let summaryPromise = repository.brand.getSummaryById(id: brandId)
    async let brandPromise = repository.brand.getJoinedById(id: brandId)

    switch await summaryPromise {
    case let .success(summary):
      self.summary = summary
    case let .failure(error):
      guard !error.localizedDescription.contains("cancelled") else { return }
      feedbackManager.toggle(.error(.unexpected))
      logger.error("failed to load summary for brand: \(error.localizedDescription)")
    }

    switch await brandPromise {
    case let .success(brand):
      self.brand = brand
    case let .failure(error):
      guard !error.localizedDescription.contains("cancelled") else { return }
      feedbackManager.toggle(.error(.unexpected))
      logger.error("request for brand with \(brandId) failed: \(error.localizedDescription)")
    }
  }

  func getSummary() async {
    async let summaryPromise = repository.brand.getSummaryById(id: brand.id)
    switch await summaryPromise {
    case let .success(summary):
      self.summary = summary
    case let .failure(error):
      guard !error.localizedDescription.contains("cancelled") else { return }
      feedbackManager.toggle(.error(.unexpected))
      logger.error("failed to load summary for brand: \(error.localizedDescription)")
    }
  }

  func verifyBrand(brand: Brand.JoinedSubBrandsProductsCompany, isVerified: Bool) async {
    switch await repository.brand.verification(id: brand.id, isVerified: isVerified) {
    case .success:
      self.brand = Brand.JoinedSubBrandsProductsCompany(
        id: brand.id,
        name: brand.name,
        isVerified: isVerified,
        brandOwner: brand.brandOwner,
        subBrands: brand.subBrands
      )
      feedbackManager.trigger(.notification(.success))
    case let .failure(error):
      guard !error.localizedDescription.contains("cancelled") else { return }
      feedbackManager.toggle(.error(.unexpected))
      logger.error("failed to verify brand': \(error.localizedDescription)")
    }
  }

  func verifySubBrand(_ subBrand: SubBrand.JoinedProduct, isVerified: Bool) async {
    switch await repository.subBrand.verification(id: subBrand.id, isVerified: isVerified) {
    case .success:
      await refresh()
      feedbackManager.trigger(.notification(.success))
      logger.info("sub-brand succesfully verified")
    case let .failure(error):
      guard !error.localizedDescription.contains("cancelled") else { return }
      feedbackManager.toggle(.error(.unexpected))
      logger.error("failed to verify brand': \(error.localizedDescription)")
    }
  }

  func deleteBrand(_ brand: Brand.JoinedSubBrandsProductsCompany) async {
    switch await repository.brand.delete(id: brand.id) {
    case .success:
      router.reset()
      feedbackManager.trigger(.notification(.success))
    case let .failure(error):
      guard !error.localizedDescription.contains("cancelled") else { return }
      feedbackManager.toggle(.error(.unexpected))
      logger.error("failed to delete brand: \(error.localizedDescription)")
    }
  }

  func deleteSubBrand(_: SubBrand.JoinedProduct) async {
    guard let toDeleteSubBrand else { return }
    switch await repository.subBrand.delete(id: toDeleteSubBrand.id) {
    case .success:
      await refresh()
      feedbackManager.trigger(.notification(.success))
      logger.info("succesfully deleted sub-brand")
    case let .failure(error):
      guard !error.localizedDescription.contains("cancelled") else { return }
      feedbackManager.toggle(.error(.unexpected))
      logger.error("failed to delete brand '\(toDeleteSubBrand.id)': \(error.localizedDescription)")
    }
  }
}
