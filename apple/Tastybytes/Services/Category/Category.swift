protocol CategoryName {
  var name: String { get }
  var icon: String { get }
}

extension CategoryName {
  var label: String {
    "\(icon) \(name)"
  }
}

protocol CategoryProtocol {
  var id: Int { get }
  var name: String { get }
}

struct Category: Identifiable, Decodable, Hashable, CategoryName, CategoryProtocol {
  let id: Int
  let name: String
  let icon: String
}

extension Category {
  static func getQuery(_ queryType: QueryType) -> String {
    let tableName = "categories"
    let servingStyleTableName = "category_serving_styles"
    let saved = "id, name, icon"

    switch queryType {
    case .tableName:
      return tableName
    case .servingStyleTableName:
      return servingStyleTableName
    case let .saved(withTableName):
      return queryWithTableName(tableName, saved, withTableName)
    case let .joinedSubcategories(withTableName):
      return queryWithTableName(tableName, [saved, Subcategory.getQuery(.saved(true))].joinComma(), withTableName)
    case let .joinedServingStyles(withTableName):
      return queryWithTableName(tableName, [saved, ServingStyle.getQuery(.saved(true))].joinComma(), withTableName)
    case let .joinedSubcaategoriesServingStyles(withTableName):
      return queryWithTableName(
        tableName,
        [saved, Subcategory.getQuery(.saved(true)), ServingStyle.getQuery(.saved(true))].joinComma(),
        withTableName
      )
    }
  }

  enum QueryType {
    case tableName
    case servingStyleTableName
    case saved(_ withTableName: Bool)
    case joinedSubcategories(_ withTableName: Bool)
    case joinedServingStyles(_ withTableName: Bool)
    case joinedSubcaategoriesServingStyles(_ withTableName: Bool)
  }
}

extension Category {
  struct JoinedSubcategories: Identifiable, Decodable, Hashable, Sendable, CategoryProtocol {
    let id: Int
    let name: String
    let icon: String
    let subcategories: [Subcategory]
  }

  struct JoinedSubcategoriesServingStyles: Identifiable, Decodable, Hashable, Sendable, CategoryProtocol {
    let id: Int
    let name: String
    let subcategories: [Subcategory]
    let servingStyles: [ServingStyle]

    enum CodingKeys: String, CodingKey {
      case id
      case name
      case subcategories
      case servingStyles = "serving_styles"
    }
  }

  struct JoinedServingStyles: Identifiable, Decodable, Hashable, Sendable, CategoryProtocol {
    let id: Int
    let name: String
    let servingStyles: [ServingStyle]

    enum CodingKeys: String, CodingKey {
      case id
      case name
      case servingStyles = "serving_styles"
    }
  }

  struct NewRequest: Encodable, Sendable {
    let name: String
  }

  struct NewServingStyleRequest: Encodable, Sendable {
    let categoryId: Int
    let servingStyleId: Int

    enum CodingKeys: String, CodingKey {
      case categoryId = "category_id"
      case servingStyleId = "serving_style_id"
    }
  }
}
