import Models
import Supabase

struct SupabaseSubBrandRepository: SubBrandRepository {
    let client: SupabaseClient

    func insert(newSubBrand: SubBrand.NewRequest) async -> Result<SubBrand, Error> {
        do {
            let response: SubBrand = try await client
                .database
                .from(.subBrands)
                .insert(newSubBrand, returning: .representation)
                .select(SubBrand.getQuery(.saved(false)))
                .single()
                .execute()
                .value

            return .success(response)
        } catch {
            return .failure(error)
        }
    }

    func update(updateRequest: SubBrand.Update) async -> Result<Void, Error> {
        do {
            let baseQuery = await client
                .database
                .from(.subBrands)

            switch updateRequest {
            case let .brand(update):
                try await baseQuery
                    .update(update)
                    .eq("id", value: update.id)
                    .execute()
            case let .name(update):
                try await baseQuery
                    .update(update)
                    .eq("id", value: update.id)
                    .execute()
            }

            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func delete(id: Int) async -> Result<Void, Error> {
        do {
            try await client
                .database
                .from(.subBrands)
                .delete()
                .eq("id", value: id)
                .execute()

            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func verification(id: Int, isVerified: Bool) async -> Result<Void, Error> {
        do {
            try await client
                .database
                .rpc(fn: .verifySubBrand, params: SubBrand.VerifyRequest(id: id, isVerified: isVerified))
                .single()
                .execute()

            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func getUnverified() async -> Result<[SubBrand.JoinedBrand], Error> {
        do {
            let response: [SubBrand.JoinedBrand] = try await client
                .database
                .from(.subBrands)
                .select(SubBrand.getQuery(.joinedBrand(false)))
                .eq("is_verified", value: false)
                .order("created_at", ascending: false)
                .execute()
                .value

            return .success(response)
        } catch {
            return .failure(error)
        }
    }
}
