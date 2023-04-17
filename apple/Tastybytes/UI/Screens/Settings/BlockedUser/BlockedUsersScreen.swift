import SwiftUI

struct BlockedUsersScreen: View {
  @EnvironmentObject private var friendManager: FriendManager
  @EnvironmentObject private var feedbackManager: FeedbackManager
  @State private var showUserSearchSheet = false

  var body: some View {
    List {
      if friendManager.blockedUsers.isEmpty {
        Text("You haven't blocked any users")
      }
      ForEach(friendManager.blockedUsers) { friend in
        BlockedUserListItemView(profile: friend.getFriend(userId: friendManager.profile.id), onUnblockUser: {
          await friendManager.unblockUser(friend)
        })
      }
    }
    .navigationTitle("Blocked Users")
    .navigationBarItems(
      trailing: blockUser
    )
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      await friendManager.loadFriends()
    }
  }

  private var blockUser: some View {
    HStack {
      RouterLink("Show block user sheet", systemImage: "plus", sheet: .userSheet(mode: .block, onSubmit: {
        feedbackManager.toggle(.success("User blocked"))
      }))
      .labelStyle(.iconOnly)
      .imageScale(.large)
    }
  }
}
