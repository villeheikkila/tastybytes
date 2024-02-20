import Components
import EnvironmentModels
import Models
import SwiftUI

@MainActor
struct CurrentUserFriendsScreen: View {
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @Environment(FriendEnvironmentModel.self) private var friendEnvironmentModel
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @Environment(NotificationEnvironmentModel.self) private var notificationEnvironmentModel
    @State private var friendToBeRemoved: Friend? {
        didSet {
            showRemoveFriendConfirmation = true
        }
    }

    @State private var showRemoveFriendConfirmation = false
    @State private var showUserSearchSheet = false
    @State private var searchTerm = ""
    @State private var sheet: Sheet?

    var filteredFriends: [Friend] {
        friendEnvironmentModel.acceptedOrPendingFriends.filter { friend in
            searchTerm.isEmpty
                || friend.getFriend(userId: profileEnvironmentModel.id).preferredName.lowercased()
                .contains(searchTerm.lowercased())
        }
    }

    var body: some View {
        List(filteredFriends) { friend in
            FriendListItemView(profile: friend.getFriend(userId: profileEnvironmentModel.profile.id)) {
                HStack {
                    if friend.status == .pending {
                        Text(friend.status.label)
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    if friend.isPending(userId: profileEnvironmentModel.profile.id) {
                        HStack(alignment: .center) {
                            Label("friends.action.removeFriendRequest.label", systemImage: "person.fill.xmark")
                                .imageScale(.large)
                                .labelStyle(.iconOnly)
                                .accessibilityAddTraits(.isButton)
                                .onTapGesture {
                                    friendToBeRemoved = friend
                                }
                            Label("friends.acceptRequest.label", systemImage: "person.badge.plus")
                                .imageScale(.large)
                                .labelStyle(.iconOnly)
                                .accessibilityAddTraits(.isButton)
                                .onTapGesture {
                                    Task {
                                        await friendEnvironmentModel.updateFriendRequest(
                                            friend: friend,
                                            newStatus: .accepted
                                        )
                                    }
                                }
                        }
                    }
                }
            }
            .swipeActions {
                Group {
                    if friend.isPending(userId: profileEnvironmentModel.profile.id) {
                        ProgressButton(
                            "friends.acceptRequest.label",
                            systemImage: "person.badge.plus",
                            action: {
                                await friendEnvironmentModel.updateFriendRequest(
                                    friend: friend,
                                    newStatus: .accepted
                                )
                            }
                        )
                        .tint(.green)
                    }
                    Button(
                        "labels.delete",
                        systemImage: "person.fill.xmark",
                        role: .destructive,
                        action: { friendToBeRemoved = friend }
                    )
                    ProgressButton(
                        "friends.block.label",
                        systemImage: "person.2.slash",
                        action: {
                            await friendEnvironmentModel.updateFriendRequest(friend: friend, newStatus: .blocked)
                        }
                    )
                }.imageScale(.large)
            }
            .contextMenu {
                Button(
                    "labels.delete",
                    systemImage: "person.fill.xmark",
                    role: .destructive,
                    action: { friendToBeRemoved = friend }
                )
                ProgressButton(
                    "friends.block.label",
                    systemImage: "person.2.slash",
                    action: {
                        await friendEnvironmentModel.updateFriendRequest(friend: friend, newStatus: .blocked)
                    }
                )
            }
        }
        .listStyle(.insetGrouped)
        .sensoryFeedback(.success, trigger: friendEnvironmentModel.isRefreshing) { oldValue, newValue in
            oldValue && !newValue
        }
        .overlay {
            if friendEnvironmentModel.friends.isEmpty {
                ContentUnavailableView {
                    Label("friends.contentUnavailable.noFriends", systemImage: "person.3")
                }
            } else if !searchTerm.isEmpty, filteredFriends.isEmpty {
                ContentUnavailableView.search(text: searchTerm)
            }
        }
        .navigationTitle("friends.title \(friendEnvironmentModel.friends.count.formatted())")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchTerm, placement: .navigationBarDrawer(displayMode: .always))
        .refreshable {
            await friendEnvironmentModel.refresh(withHaptics: true)
        }
        .task {
            await friendEnvironmentModel.refresh()
            await notificationEnvironmentModel.markAllFriendRequestsAsRead()
        }
        .toolbar {
            toolbarContent
        }
        .sheets(item: $sheet)
        .confirmationDialog("friend.delete.confirmation.title",
                            isPresented: $showRemoveFriendConfirmation,
                            titleVisibility: .visible,
                            presenting: friendToBeRemoved)
        { presenting in
            ProgressButton(
                "friend.delete.confirmation.label \(presenting.getFriend(userId: profileEnvironmentModel.id).preferredName)",
                role: .destructive,
                action: {
                    await friendEnvironmentModel.removeFriendRequest(presenting)
                }
            )
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(
                "friends.toolbar.showNameTag",
                systemImage: "qrcode",
                action: { sheet = .nameTag(onSuccess: { profileId in
                    Task {
                        await friendEnvironmentModel.sendFriendRequest(receiver: profileId)
                    }
                }) }
            )
            .labelStyle(.iconOnly)
            .imageScale(.large)
            .popoverTip(NameTagTip())

            Button(
                "friends.add.label", systemImage: "plus",
                action: { sheet = .userSheet(
                    mode: .add,
                    onSubmit: {
                        feedbackEnvironmentModel.toggle(.success("friends.add.success"))
                    }
                ) }
            )
            .labelStyle(.iconOnly)
            .imageScale(.large)
        }
    }
}
