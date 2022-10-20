import SwiftUI

struct UserSearchView<Actions: View>: View {
    @State var searchText: String = ""
    @State var searchResults = [Profile]()

    let actions: (_ profile: Profile) -> Actions

    var body: some View {

        NavigationStack {
            List {
                ForEach(searchResults, id: \.id) { profile in
                        HStack {
                                
                                AvatarView(avatarUrl: profile.getAvatarURL(), size: 32, id: profile.id)
                                Text(profile.getPreferedName())
                            
                            Spacer()
                            HStack {
                                self.actions(profile)
                            }
                        }
                }
            }
            .navigationTitle("Search users")
            .searchable(text: $searchText)
            .onSubmit(of: .search, searchUsers)
            
        }
    }
    
    func searchUsers() {
        Task {
            do {
                let currentUserId = repository.auth.getCurrentUserId()
                let searchResults = try await repository.profile.search(searchTerm: searchText, currentUserId: currentUserId)
                DispatchQueue.main.async {
                    self.searchResults = searchResults
                }
            } catch {
                print("error: \(error.localizedDescription)")
            }
        }
    }
}
