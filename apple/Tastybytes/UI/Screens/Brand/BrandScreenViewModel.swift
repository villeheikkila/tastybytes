import SwiftUI

extension BrandScreen {
  @MainActor
  class ViewModel: ObservableObject {
    private let logger = getLogger(category: "BrandScreen")
    let client: Client
    let refreshOnLoad: Bool
    @Published var brand: Brand.JoinedSubBrandsProductsCompany
    @Published var summary: Summary?
    @Published var editBrand: Brand.JoinedSubBrandsProductsCompany?
    @Published var toUnverifySubBrand: SubBrand.JoinedProduct? {
      didSet {
        showSubBrandUnverificationConfirmation = true
      }
    }

    @Published var showSubBrandUnverificationConfirmation = false
    @Published var showBrandUnverificationConfirmation = false
    @Published var showDeleteProductConfirmationDialog = false
    @Published var productToDelete: Product.JoinedCategory? {
      didSet {
        if productToDelete != nil {
          showDeleteProductConfirmationDialog = true
        }
      }
    }

    @Published var showDeleteBrandConfirmationDialog = false
    @Published var brandToDelete: Brand.JoinedSubBrandsProducts? {
      didSet {
        showDeleteBrandConfirmationDialog = true
      }
    }

    @Published var showDeleteSubBrandConfirmation = false
    @Published var toDeleteSubBrand: SubBrand.JoinedProduct? {
      didSet {
        if oldValue == nil {
          showDeleteSubBrandConfirmation = true
        } else {
          showDeleteSubBrandConfirmation = false
        }
      }
    }

    init(_ client: Client, brand: Brand.JoinedSubBrandsProductsCompany, refreshOnLoad: Bool?) {
      self.client = client
      self.brand = brand
      self.refreshOnLoad = refreshOnLoad ?? false
    }

    var sortedSubBrands: [SubBrand.JoinedProduct] {
      brand.subBrands
        .filter { !($0.name == nil && $0.products.isEmpty) }
        .sorted { lhs, rhs -> Bool in
          switch (lhs.name, rhs.name) {
          case let (lhs?, rhs?): return lhs < rhs
          case (nil, _): return true
          case (_?, nil): return false
          }
        }
    }

    func refresh() async {
      let brandId = brand.id
      async let summaryPromise = client.brand.getSummaryById(id: brandId)
      async let brandPromise = client.brand.getJoinedById(id: brandId)

      switch await summaryPromise {
      case let .success(summary):
        self.summary = summary
      case let .failure(error):
        logger.error("failed to load summary for brand: \(error.localizedDescription)")
      }

      switch await brandPromise {
      case let .success(brand):
        self.brand = brand
      case let .failure(error):
        logger.error("request for brand with \(brandId) failed: \(error.localizedDescription)")
      }
    }

    func getSummary() async {
      async let summaryPromise = client.brand.getSummaryById(id: brand.id)
      switch await summaryPromise {
      case let .success(summary):
        self.summary = summary
      case let .failure(error):
        logger.error("failed to load summary for brand: \(error.localizedDescription)")
      }
    }

    func verifyBrand(isVerified: Bool) async {
      switch await client.brand.verification(id: brand.id, isVerified: isVerified) {
      case .success:
        brand = Brand.JoinedSubBrandsProductsCompany(
          id: brand.id,
          name: brand.name,
          isVerified: isVerified,
          brandOwner: brand.brandOwner,
          subBrands: brand.subBrands
        )
      case let .failure(error):
        logger.error("failed to verify brand': \(error.localizedDescription)")
      }
    }

    func verifySubBrand(_ subBrand: SubBrand.JoinedProduct, isVerified: Bool) async {
      switch await client.subBrand.verification(id: subBrand.id, isVerified: isVerified) {
      case .success:
        await refresh()
        logger.info("sub-brand succesfully verified")
      case let .failure(error):
        logger.error("failed to verify brand': \(error.localizedDescription)")
      }
    }

    func deleteBrand(onDelete: @escaping () -> Void) async {
      switch await client.brand.delete(id: brand.id) {
      case .success:
        onDelete()
      case let .failure(error):
        logger.error("failed to delete brand: \(error.localizedDescription)")
      }
    }

    func deleteSubBrand() async {
      guard let toDeleteSubBrand else { return }
      switch await client.subBrand.delete(id: toDeleteSubBrand.id) {
      case .success:
        await refresh()
        logger.info("succesfully deleted sub-brand")
      case let .failure(error):
        logger.error("failed to delete brand '\(toDeleteSubBrand.id)': \(error.localizedDescription)")
      }
    }
  }
}
