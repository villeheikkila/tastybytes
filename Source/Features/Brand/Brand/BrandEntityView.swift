import Models
import SwiftUI

struct BrandEntityView: View {
    let brandOwner: Company?
    let brand: BrandProtocol

    init(brand: Brand.JoinedSubBrandsProductsCompany) {
        self.brand = brand
        brandOwner = brand.brandOwner
    }

    init(brand: BrandProtocol) {
        self.brand = brand
        brandOwner = nil
    }

    var body: some View {
        HStack {
            BrandLogoView(brand: brand, size: 40)
            VStack(alignment: .leading) {
                if let brandOwner {
                    Text(brandOwner.name)
                }
                HStack {
                    Text(brand.name)
                    Spacer()
                    VerifiedBadgeView(verifiable: brand)
                }
            }
        }
    }
}
