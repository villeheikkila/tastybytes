struct Role: Identifiable, Decodable, Hashable {
  let id: Int
  let name: String
  let permissions: [Permission]

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case permissions
  }
}

extension Role {
  static func getQuery(_ queryType: QueryType) -> String {
    let tableName = "roles"
    let saved = "id, name"

    switch queryType {
    case .tableName:
      return tableName
    case let .joined(withTableName):
      return queryWithTableName(tableName, joinWithComma(saved, Permission.getQuery(.saved(true))), withTableName)
    }
  }

  enum QueryType {
    case tableName
    case joined(_ withTableName: Bool)
  }
}
