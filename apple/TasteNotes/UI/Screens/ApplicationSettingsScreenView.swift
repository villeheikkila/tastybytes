import SwiftUI

struct ApplicationSettingsScreenView: View {
    @StateObject private var viewModel = ViewModel()
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.colorScheme) var systemColorScheme

    var body: some View {
        Form {
            Section {
                Toggle("Use System Color Scheme", isOn: $viewModel.isSystemColor).onChange(of: [self.viewModel.isSystemColor].publisher.first()) { _ in
                    viewModel.updateColorScheme({ profileManager.refresh() })
                }
                Toggle("Use Dark Mode", isOn: $viewModel.isDarkMode).onChange(of: [self.viewModel.isDarkMode].publisher.first()) { _ in
                    viewModel.updateColorScheme({ profileManager.refresh() })
                }.disabled(viewModel.isSystemColor)
            } header: {
                Text("Color Scheme")
            }

            Section {
                Toggle("Reactions", isOn: $viewModel.reactionNotifications).onChange(of: [self.viewModel.reactionNotifications].publisher.first()) { _ in
                    viewModel.updateNotificationSettings()
                }
                Toggle("Friend Requests", isOn: $viewModel.friendRequestNotifications).onChange(of: [self.viewModel.friendRequestNotifications].publisher.first()) { _ in
                    viewModel.updateNotificationSettings()
                }
                Toggle("Check-in tags", isOn: $viewModel.checkInTagNotifications).onChange(of: [self.viewModel.checkInTagNotifications].publisher.first()) { _ in
                    viewModel.updateNotificationSettings()
                }
            } header: {
                Text("Notifications")
            }
        }
        .navigationTitle("Application")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.setInitialValues(systemColorScheme: systemColorScheme, profile: profileManager.get())
        }
    }
}

extension ApplicationSettingsScreenView {
    enum Toast {
        case profileUpdated
        case exported
        case exportError
    }

    @MainActor class ViewModel: ObservableObject {
        @Published var isSystemColor = false
        @Published var isDarkMode = false
        @Published var reactionNotifications = true
        @Published var friendRequestNotifications = true
        @Published var checkInTagNotifications = true

        var initialColorScheme: ColorScheme?

        func setInitialValues(systemColorScheme: ColorScheme, profile: Profile.Extended?) {
            Task {
                switch await repository.profile.getCurrentUser() {
                case let .success(profile):
                    await MainActor.run {
                        switch profile.settings.colorScheme {
                        case .light:
                            self.isDarkMode = false
                            self.isSystemColor = false
                        case .dark:
                            self.isDarkMode = true
                            self.isSystemColor = false
                        case .system:
                            self.isDarkMode = initialColorScheme == ColorScheme.dark
                            self.isSystemColor = true
                        }

                        self.reactionNotifications = profile.settings.sendReactionNotifications
                        self.friendRequestNotifications = profile.settings.sendFriendRequestNotifications
                        self.checkInTagNotifications = profile.settings.sendTaggedCheckInNotifications

                        initialColorScheme = systemColorScheme
                    }
                case let .failure(error):
                    print(error)
                }
            }
        }

        func updateColorScheme(_ onChange: @escaping () -> Void) {
            if isSystemColor {
                isDarkMode = initialColorScheme == ColorScheme.dark
            }
            let update = ProfileSettings.Update(
                isDarkMode: isDarkMode, isSystemColor: isSystemColor
            )

            Task {
                switch await repository.profile.updateSettings(id: repository.auth.getCurrentUserId(),
                                                               update: update) {
                case .success(_):
                    onChange()
                case let .failure(error):
                    print(error)
                }
            }
        }

        func updateNotificationSettings() {
            let update = ProfileSettings.Update(sendReactionNotifications: reactionNotifications, sendTaggedCheckInNotifications: friendRequestNotifications, sendFriendRequestNotifications: checkInTagNotifications
            )

            Task {
                _ = await repository.profile.updateSettings(id: repository.auth.getCurrentUserId(),
                                                            update: update)
            }
        }
    }
}
