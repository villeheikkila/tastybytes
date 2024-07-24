import Models
import SwiftUI

public struct CategoryView: View {
    let category: Models.Category.Saved
    let subcategories: [SubcategoryProtocol]
    let servingStyle: ServingStyle.Saved?

    public init(
        category: Models.Category.Saved,
        subcategories: [SubcategoryProtocol],
        servingStyle: ServingStyle.Saved? = nil
    ) {
        self.category = category
        self.subcategories = subcategories
        self.servingStyle = servingStyle
    }

    public var body: some View {
        HStack(spacing: 4) {
            CategoryNameView(category: category)
            ForEach(subcategories, id: \.id) { subcategory in
                SubcategoryLabelView(subcategory: subcategory)
            }
            if let servingStyle {
                ServingStyleLabelView(servingStyle: servingStyle)
            }
        }
    }
}

#Preview {
    CategoryView(
        category: .init(id: 0, name: "beverage", icon: "🥤"),
        subcategories: [Subcategory.Saved(id: 0, name: "BCAA", isVerified: true)],
        servingStyle: .init(
            id: 1,
            name: "Can"
        )
    )
}
