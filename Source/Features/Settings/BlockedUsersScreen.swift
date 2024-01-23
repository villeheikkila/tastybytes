import Components
import EnvironmentModels
import Models
import SwiftUI

@MainActor
struct BlockedUsersScreen: View {
    @Environment(FriendEnvironmentModel.self) private var friendEnvironmentModel
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @State private var sheet: Sheet?

    var body: some View {
        List(friendEnvironmentModel.blockedUsers) { friend in
            BlockedUserListItemView(
                profile: friend.getFriend(userId: profileEnvironmentModel.profile.id),
                onUnblockUser: {
                    await friendEnvironmentModel.unblockUser(friend)
                }
            )
        }
        .listStyle(.insetGrouped)
        .overlay {
            ContentUnavailableView {
                Label("You haven't blocked any users", systemImage: "person.fill.xmark")
            } description: {
                Text("Blocked users can't see your check-ins or profile")
            } actions: {
                RouterLink("Block user", sheet: .userSheet(mode: .block, onSubmit: {
                    feedbackEnvironmentModel.toggle(.success("User blocked"))
                }))
            }
            .opacity(friendEnvironmentModel.blockedUsers.isEmpty ? 1 : 0)
        }
        .navigationTitle("Blocked Users")
        .sensoryFeedback(.success, trigger: friendEnvironmentModel.friends)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        #if !targetEnvironment(macCatalyst)
        .refreshable {
            await friendEnvironmentModel.refresh()
        }
        #endif
        .sheets(item: $sheet)
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            HStack {
                Button("Show block user sheet", systemImage: "plus", action: { sheet = .userSheet(mode: .block, onSubmit: {
                    feedbackEnvironmentModel.toggle(.success("User blocked"))
                }) })
                .labelStyle(.iconOnly)
                .imageScale(.large)
            }
        }
    }
}

struct BlockedUserListItemView: View {
    @Environment(AppEnvironmentModel.self) private var appEnvironmentModel
    let profile: Profile
    let onUnblockUser: () async -> Void

    var body: some View {
        HStack(alignment: .center) {
            Avatar(profile: profile, size: 32)
            VStack {
                HStack {
                    Text(profile.preferredName)
                    Spacer()
                    ProgressButton("Unblock", systemImage: "hand.raised.slash.fill", action: { await onUnblockUser() })
                }
            }
        }
    }
}
