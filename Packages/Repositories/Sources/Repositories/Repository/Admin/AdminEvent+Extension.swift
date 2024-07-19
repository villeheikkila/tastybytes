import Models

extension AdminEvent: Queryable {
    static func getQuery(_ queryType: QueryType) -> String {
        let saved = "id, created_at, reviewed_at"

        return switch queryType {
        case let .joined(withTableName):
            buildQuery(
                .adminEvents,
                [
                    saved,
                    buildQuery(name: "reviewed_by", foreignKey: "reviewed_by", [Profile.getQuery(.minimal(false))]),
                    Company.getQuery(.saved(true)),
                    Product.getQuery(.joinedBrandSubcategories(true)),
                    buildQuery(name: "profiles", foreignKey: "profile_id", [Profile.getQuery(.minimal(false))]),
                    SubBrand.getQuery(.joinedBrand(true)),
                    Brand.getQuery(.joined(true)),
                    Product.EditSuggestion.getQuery(.joined(true)),
                    SubBrand.EditSuggestion.getQuery(.joined(true)),
                    Company.EditSuggestion.getQuery(.joined(true)),
                    Brand.EditSuggestion.getQuery(.joined(true)),
                    Product.DuplicateSuggestion.getQuery(.joined(true)),
                    Report.getQuery(.joined(true)),
                ],
                withTableName
            )
        }
    }

    enum QueryType {
        case joined(_ withTableName: Bool)
    }
}
