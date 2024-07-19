import Foundation
import Models

extension Brand: Queryable {
    static func getQuery(_ queryType: QueryType) -> String {
        let saved = "id, name, is_verified"

        return switch queryType {
        case let .saved(withTableName):
            buildQuery(.brands, [saved, ImageEntity.getQuery(.saved(.brandLogos))], withTableName)
        case let .joinedSubBrands(withTableName):
            buildQuery(.brands, [saved, SubBrand.getQuery(.saved(true)), ImageEntity.getQuery(.saved(.brandLogos))], withTableName)
        case let .joined(withTableName):
            buildQuery(.brands, [saved, SubBrand.getQuery(.joined(true)), ImageEntity.getQuery(.saved(.brandLogos))], withTableName)
        case let .joinedCompany(withTableName):
            buildQuery(.brands, [saved, Company.getQuery(.saved(true)), ImageEntity.getQuery(.saved(.brandLogos))], withTableName)
        case let .joinedSubBrandsCompany(withTableName):
            buildQuery(
                .brands,
                [saved, SubBrand.getQuery(.joined(true)), Company.getQuery(.saved(true)), ImageEntity.getQuery(.saved(.brandLogos))],
                withTableName
            )
        case let .detailed(withTableName):
            buildQuery(
                .brands,
                [
                    saved,
                    SubBrand.getQuery(.joined(true)),
                    Company.getQuery(.saved(true)),
                    ImageEntity.getQuery(.saved(.brandLogos)),
                    Brand.EditSuggestion.getQuery(.joined(true)),
                    modificationInfoFragment,
                ],
                withTableName
            )
        }
    }

    enum QueryType {
        case saved(_ withTableName: Bool)
        case joined(_ withTableName: Bool)
        case joinedSubBrands(_ withTableName: Bool)
        case joinedCompany(_ withTableName: Bool)
        case joinedSubBrandsCompany(_ withTableName: Bool)
        case detailed(_ withTableName: Bool)
    }
}

extension Brand.EditSuggestion: Queryable {
    static func getQuery(_ queryType: QueryType) -> String {
        let saved = "id, name, created_at, resolved_at"

        return switch queryType {
        case let .joined(withTableName):
            buildQuery(
                .brandEditSuggestions,
                [saved, Brand.getQuery(.saved(true)), Profile.getQuery(.minimal(true)), Company.getQuery(.saved(true))],
                withTableName
            )
        }
    }

    enum QueryType {
        case joined(_ withTableName: Bool)
    }
}
