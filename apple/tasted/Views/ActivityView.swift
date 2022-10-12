import SwiftUI

struct SimpleCheckIn {
    let name: String
    let subBrandName: String
    let brandName: String
    let companyName: String
    let rating: Double
    let creator: String
}

struct ActivityView: View {
    @StateObject private var model = ActivityViewModel()

    var body: some View {
        ScrollView {
            ForEach(model.checkIns, id: \.id) { checkIn in
                NavigationLink(value: checkIn) {
                    CheckInCardView(checkIn: checkIn)
                }
            }

        }.task {
            model.getActivityFeed()
        }
    }
}

extension ActivityView {
    @MainActor class ActivityViewModel: ObservableObject {
        @Published var checkIns = [CheckInResponse]()

        func getActivityFeed() {
            let query = API.supabase.database
                .rpc(fn: "fnc__get_activity_feed")
                .select(columns: "id, rating, review, created_at, profiles (id, username, avatar_url), products (id, name, description, sub_brands (id, name, brands (id, name, companies (id, name))), subcategories (id, name, categories (id, name))), check_in_reactions (id, created_by, profiles (id, username, avatar_url))")
                .limit(count: 5)

            Task {
                let checkIns = try await query.execute().decoded(to: [CheckInResponse].self)
                DispatchQueue.main.async {
                    self.checkIns = checkIns
                }
            }
        }
    }
}
