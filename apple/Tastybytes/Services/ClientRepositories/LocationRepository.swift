import Foundation
import Supabase

protocol LocationRepository {
  func insert(location: Location) async -> Result<Location, Error>
  func getById(id: UUID) async -> Result<Location, Error>
  func delete(id: UUID) async -> Result<Void, Error>
  func search(searchTerm: String) async -> Result<[Location], Error>
  func getSummaryById(id: UUID) async -> Result<Summary, Error>
}

struct SupabaseLocationRepository: LocationRepository {
  let client: SupabaseClient

  func insert(location: Location) async -> Result<Location, Error> {
    do {
      let result: Location = try await client
        .database
        .rpc(fn: "fnc__get_location_insert_if_not_exist", params: location)
        .select(columns: Location.getQuery(.joined(false)))
        .single()
        .execute()
        .value

      return .success(result)
    } catch {
      return .failure(error)
    }
  }

  func getById(id: UUID) async -> Result<Location, Error> {
    do {
      let response: Location = try await client
        .database
        .from(Location.getQuery(.tableName))
        .select(columns: Location.getQuery(.joined(false)))
        .eq(column: "id", value: id)
        .limit(count: 1)
        .single()
        .execute()
        .value

      return .success(response)
    } catch {
      return .failure(error)
    }
  }

  func delete(id: UUID) async -> Result<Void, Error> {
    do {
      try await client
        .database
        .from(Location.getQuery(.tableName))
        .delete()
        .eq(column: "id", value: id)
        .execute()

      return .success(())
    } catch {
      return .failure(error)
    }
  }

  func search(searchTerm: String) async -> Result<[Location], Error> {
    do {
      let response: [Location] = try await client
        .database
        .from(Location.getQuery(.tableName))
        .select(columns: Location.getQuery(.joined(false)))
        .ilike(column: "name", value: "%\(searchTerm)%")
        .execute()
        .value

      return .success(response)
    } catch {
      return .failure(error)
    }
  }

  func getSummaryById(id: UUID) async -> Result<Summary, Error> {
    do {
      let response: Summary = try await client
        .database
        .rpc(fn: "fnc__get_location_summary", params: Location.SummaryRequest(id: id))
        .select()
        .limit(count: 1)
        .single()
        .execute()
        .value

      return .success(response)
    } catch {
      return .failure(error)
    }
  }
}
