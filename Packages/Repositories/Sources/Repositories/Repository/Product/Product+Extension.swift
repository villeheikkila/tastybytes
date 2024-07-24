import Foundation
import Models

extension Product: Queryable {
    private static let saved = "id, name, description, is_verified, is_discontinued"

    static func getQuery(_ queryType: QueryType) -> String {
        switch queryType {
        case let .saved(withTableName):
            buildQuery(.products, [saved, ImageEntity.getQuery(.saved(.productLogos))], withTableName)
        case let .joinedBrandSubcategories(withTableName):
            buildQuery(
                .products,
                [saved, SubBrand.getQuery(.joinedBrand(true)), Category.getQuery(.saved(true)),
                 Subcategory.getQuery(.joinedCategory(true)), Product.Barcode.getQuery(.saved(true)), ImageEntity.getQuery(.saved(.productLogos))],
                withTableName
            )
        case let .joinedBrandSubcategoriesCreator(withTableName):
            buildQuery(
                .products,
                [
                    saved,
                    buildQuery(name: "profiles", foreignKey: "created_by", [Profile.getQuery(.minimal(false))]),
                    SubBrand.getQuery(.joinedBrand(true)),
                    Category.getQuery(.saved(true)),
                    Subcategory.getQuery(.joinedCategory(true)),
                    Product.Barcode.getQuery(.saved(true)),
                    ImageEntity.getQuery(.saved(.productLogos)),
                ],
                withTableName
            )
        case let .joinedBrandSubcategoriesRatings(withTableName):
            buildQuery(
                .products,
                [
                    saved,
                    "current_user_check_ins",
                    "average_rating",
                    SubBrand.getQuery(.joinedBrand(true)),
                    Category.getQuery(.saved(true)),
                    Subcategory.getQuery(.joinedCategory(true)),
                    Product.Barcode.getQuery(.saved(true)),
                    ImageEntity.getQuery(.saved(.productLogos)),
                ],
                withTableName
            )
        case let .joinedBrandSubcategoriesProfileRatings(withTableName):
            buildQuery(
                .products,
                [
                    saved,
                    "check_ins",
                    "average_rating",
                    SubBrand.getQuery(.joinedBrand(true)),
                    Category.getQuery(.saved(true)),
                    Subcategory.getQuery(.joinedCategory(true)),
                    Product.Barcode.getQuery(.saved(true)),
                    ImageEntity.getQuery(.saved(.productLogos)),
                ],
                withTableName
            )
        case let .detailed(withTableName):
            buildQuery(
                .products,
                [
                    saved,
                    SubBrand.getQuery(.joinedBrand(true)),
                    Category.getQuery(.saved(true)),
                    Subcategory.getQuery(.joinedCategory(true)),
                    Product.Barcode.getQuery(.joinedCreator(true)),
                    buildQuery(name: "product_edit_suggestions", foreignKey: "product_edit_suggestions!product_edit_suggestions_product_id_fkey", [Product.EditSuggestion.getQuery(.joined(false))]),
                    Product.Variant.getQuery(.joinedCompany(true)),
                    Report.getQuery(.joined(true)),
                    ImageEntity.getQuery(.saved(.productLogos)),
                    modificationInfoFragment,
                ],
                withTableName
            )
        }
    }

    enum QueryType {
        case saved(_ withTableName: Bool)
        case joinedBrandSubcategories(_ withTableName: Bool)
        case joinedBrandSubcategoriesCreator(_ withTableName: Bool)
        case joinedBrandSubcategoriesRatings(_ withTableName: Bool)
        case joinedBrandSubcategoriesProfileRatings(_ withTableName: Bool)
        case detailed(_ withTableName: Bool)
    }
}

extension Product.Variant: Queryable {
    private static let saved = "id"

    static func getQuery(_ queryType: QueryType) -> String {
        switch queryType {
        case let .joinedCompany(withTableName):
            buildQuery(.productVariants, [saved, Company.getQuery(.saved(true))], withTableName)
        case let .joinedProduct(withTableName):
            buildQuery(.productVariants, [saved, Product.getQuery(.joinedBrandSubcategories(true))], withTableName)
        }
    }

    enum QueryType {
        case joinedCompany(_ withTableName: Bool)
        case joinedProduct(_ withTableName: Bool)
    }
}

extension Product.EditSuggestion: Queryable {
    private static let saved = "id, created_at, name, description, is_discontinued"

    static func getQuery(_ queryType: QueryType) -> String {
        switch queryType {
        case let .joined(withTableName):
            buildQuery(
                .productEditSuggestions,
                [
                    saved,
                    buildQuery(name: "products", foreignKey: "products!product_edit_suggestions_product_id_fkey", [Product.getQuery(.joinedBrandSubcategories(false))]),
                    buildQuery(name: "duplicate_of", foreignKey: "fk_duplicate_product_id", [Product.getQuery(.joinedBrandSubcategories(false))]),
                    Profile.getQuery(.minimal(true)),
                    Category.getQuery(.saved(true)),
                    SubBrand.getQuery(.joinedBrand(true)),
                    Product.EditSuggestion.SubcategoryEditSuggestion.getQuery(.joined(true)),
                ],
                withTableName
            )
        }
    }

    enum QueryType {
        case joined(_ withTableName: Bool)
    }
}

extension Product.EditSuggestion.SubcategoryEditSuggestion: Queryable {
    private static let saved = "id, delete"

    static func getQuery(_ queryType: QueryType) -> String {
        switch queryType {
        case let .joined(withTableName):
            buildQuery(
                .productEditSuggestionSubcategories,
                [
                    saved,
                    Subcategory.getQuery(.joinedCategory(true)),
                ],
                withTableName
            )
        }
    }

    enum QueryType {
        case joined(_ withTableName: Bool)
    }
}
