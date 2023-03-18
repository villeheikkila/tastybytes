protocol SubBrandProtocol {
  var id: Int { get }
  var name: String? { get }
  var isVerified: Bool { get }
}

struct SubBrand: Identifiable, Hashable, Decodable, Sendable, SubBrandProtocol {
  let id: Int
  let name: String?
  let isVerified: Bool

  init(id: Int, name: String?, isVerified: Bool) {
    self.id = id
    self.name = name
    self.isVerified = isVerified
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case isVerified = "is_verified"
  }
}

extension SubBrand {
  static func getQuery(_ queryType: QueryType) -> String {
    let tableName = "sub_brands"
    let saved = "id, name, is_verified"

    switch queryType {
    case .tableName:
      return tableName
    case let .saved(withTableName):
      return queryWithTableName(tableName, saved, withTableName)
    case let .joined(withTableName):
      return queryWithTableName(
        tableName,
        [saved, Product.getQuery(.joinedBrandSubcategories(true))].joinComma(),
        withTableName
      )
    case let .joinedBrand(withTableName):
      return queryWithTableName(tableName, [saved, Brand.getQuery(.joinedCompany(true))].joinComma(), withTableName)
    }
  }

  enum QueryType {
    case tableName
    case saved(_ withTableName: Bool)
    case joined(_ withTableName: Bool)
    case joinedBrand(_ withTableName: Bool)
  }
}

extension SubBrand {
  struct JoinedBrand: Identifiable, Hashable, Decodable, Sendable, SubBrandProtocol {
    let id: Int
    let name: String?
    let isVerified: Bool
    let brand: Brand.JoinedCompany

    init(id: Int, name: String?, isVerified: Bool, brand: Brand.JoinedCompany) {
      self.id = id
      self.name = name
      self.brand = brand
      self.isVerified = isVerified
    }

    enum CodingKeys: String, CodingKey {
      case id
      case name
      case brand = "brands"
      case isVerified = "is_verified"
    }
  }

  struct JoinedProduct: Identifiable, Hashable, Decodable, Sendable {
    let id: Int
    let name: String?
    let isVerified: Bool
    let products: [Product.JoinedCategory]

    enum CodingKeys: String, CodingKey {
      case id
      case name
      case isVerified = "is_verified"
      case products
    }
  }
}

extension SubBrand {
  struct NewRequest: Encodable {
    let name: String
    let brandId: Int

    enum CodingKeys: String, CodingKey, Sendable {
      case name
      case brandId = "brand_id"
    }

    init(name: String, brandId: Int) {
      self.name = name
      self.brandId = brandId
    }
  }

  struct UpdateNameRequest: Encodable, Sendable {
    let id: Int
    let name: String

    init(id: Int, name: String) {
      self.id = id
      self.name = name
    }
  }

  struct UpdateBrandRequest: Encodable, Sendable {
    let id: Int
    let brandId: Int

    enum CodingKeys: String, CodingKey {
      case id, brandId = "brand_id"
    }

    init(id: Int, brandId: Int) {
      self.id = id
      self.brandId = brandId
    }
  }

  struct VerifyRequest: Encodable, Sendable {
    let id: Int
    let isVerified: Bool

    enum CodingKeys: String, CodingKey {
      case id = "p_sub_brand_id"
      case isVerified = "p_is_verified"
    }
  }

  enum Update {
    case brand(UpdateBrandRequest)
    case name(UpdateNameRequest)
  }
}
