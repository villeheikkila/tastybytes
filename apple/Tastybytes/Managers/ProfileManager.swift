import PhotosUI
import SwiftUI

@MainActor
class ProfileManager: ObservableObject {
  private let logger = getLogger(category: "ProfileManager")
  @Published private(set) var isLoggedIn = false
  @Published private(set) var colorScheme: ColorScheme?

  // Profile Settings
  @Published var username = ""
  @Published var firstName = ""
  @Published var lastName = ""
  @Published var showFullName = false
  @Published var showProfileUpdateButton = false
  @Published var isPrivateProfile = true

  // Account Settings
  @Published var email = ""
  @Published var csvExport: CSVFile?
  @Published var showingExporter = false

  // Application Settings
  @Published var initialValuesLoaded = true
  @Published var isSystemColor = false
  @Published var isDarkMode = false
  @Published var reactionNotifications = true
  @Published var friendRequestNotifications = true
  @Published var checkInTagNotifications = true

  let client: Client

  init(client: Client) {
    self.client = client
  }

  var initialColorScheme: ColorScheme?

  func updateColorScheme() async {
    if isSystemColor {
      isDarkMode = initialColorScheme == ColorScheme.dark
    }
    let update = ProfileSettings.UpdateRequest(
      isDarkMode: isDarkMode, isSystemColor: isSystemColor
    )

    switch await client.profile.updateSettings(
      update: update
    ) {
    case .success:
      setPreferredColorScheme(profileColorScheme: isSystemColor ? .system : isDarkMode ? .dark : .light)
    case let .failure(error):
      logger.error("updating color scheme failed: \(error.localizedDescription)")
    }
  }

  func updateNotificationSettings() async {
    let update = ProfileSettings.UpdateRequest(
      sendReactionNotifications: reactionNotifications,
      sendTaggedCheckInNotifications: checkInTagNotifications,
      sendFriendRequestNotifications: friendRequestNotifications
    )

    _ = await client.profile.updateSettings(
      update: update
    )
  }

  private var profile: Profile.Extended?

  func get() -> Profile.Extended {
    guard let profile else { fatalError("ProfileManager.get() can only be used on authenticated routes.") }
    return profile
  }

  func getProfile() -> Profile {
    guard let profile = profile?.getProfile()
    else { fatalError("ProfileManager.getProfile() can only be used on authenticated routes.") }
    return profile
  }

  func getId() -> UUID {
    guard let id = profile?.id
    else { fatalError("ProfileManager.getProfile() can only be used on authenticated routes.") }
    return id
  }

  func refresh() async {
    switch await client.profile.getCurrentUser() {
    case let .success(currentUserProfile):
      profile = currentUserProfile
      setPreferredColorScheme(profileColorScheme: currentUserProfile.settings.colorScheme)
      username = currentUserProfile.username
      lastName = currentUserProfile.lastName.orEmpty
      firstName = currentUserProfile.firstName.orEmpty
      showFullName = currentUserProfile.nameDisplay == Profile.NameDisplay.fullName
      isPrivateProfile = currentUserProfile.isPrivate

      switch currentUserProfile.settings.colorScheme {
      case .light:
        isDarkMode = false
        isSystemColor = false
      case .dark:
        isDarkMode = true
        isSystemColor = false
      case .system:
        isDarkMode = initialColorScheme == ColorScheme.dark
        isSystemColor = true
      }

      reactionNotifications = currentUserProfile.settings.sendReactionNotifications
      friendRequestNotifications = currentUserProfile.settings.sendFriendRequestNotifications
      checkInTagNotifications = currentUserProfile.settings.sendTaggedCheckInNotifications
      initialValuesLoaded = false
      isLoggedIn = true
    case let .failure(error):
      logger.error("error while loading current user profile: \(error.localizedDescription)")
      isLoggedIn = false
      _ = await client.auth.logOut()
    }

    switch await client.auth.getUser() {
    case let .success(user):
      email = user.email.orEmpty
    case let .failure(error):
      logger.error("failed to get current user data: \(error.localizedDescription)")
    }
  }

  func hasPermission(_ permission: PermissionName) -> Bool {
    guard let roles = profile?.roles else { return false }
    let permissions = roles.flatMap(\.permissions)
    return permissions.contains(where: { $0.name == permission.rawValue })
  }

  func setPreferredColorScheme(profileColorScheme: ProfileSettings.ColorScheme) {
    switch profileColorScheme {
    case ProfileSettings.ColorScheme.dark:
      colorScheme = ColorScheme.dark
    case ProfileSettings.ColorScheme.light:
      colorScheme = ColorScheme.light
    case ProfileSettings.ColorScheme.system:
      colorScheme = nil
    }
  }

  func logOut() async {
    _ = await client.auth.logOut()
  }

  func updatePassword(newPassword: String) async {
    _ = await client.auth.updatePassword(newPassword: newPassword)
  }

  func sendEmailVerificationLink() async {
    _ = await client.auth.sendEmailVerification(email: email)
  }

  func deleteCurrentAccount(onError: @escaping (_ error: String) -> Void) async {
    switch await client.profile.deleteCurrentAccount() {
    case .success:
      _ = await client.auth.logOut()
    case let .failure(error):
      logger.error("failed to delete current account: \(error.localizedDescription)")
      onError(error.localizedDescription)
    }
  }

  var profileHasChanged: Bool {
    !(username == profile?.username ?? "" &&
      firstName == profile?.firstName ?? "" &&
      lastName == profile?.lastName ?? "")
  }

  func uploadAvatar(newAvatar: PhotosPickerItem?) async {
    guard let data = await newAvatar?.getJPEG() else { return }
    guard let profile else { return }
    switch await client.profile.uploadAvatar(userId: profile.id, data: data) {
    case .success:
      // TODO: update only avatar url
      await refresh()
    case let .failure(error):
      logger.error("uplodaing avatar failed: \(error.localizedDescription)")
    }
  }

  func updateProfile(onSuccess: @escaping () async -> Void, onFailure: @escaping (_ error: Error) -> Void) async {
    let update = Profile.UpdateRequest(
      username: username,
      firstName: firstName,
      lastName: lastName
    )

    switch await client.profile.update(
      update: update
    ) {
    case .success:
      await onSuccess()
    case let .failure(error):
      logger.error("failed to update profile: \(error.localizedDescription)")
      onFailure(error)
    }
  }

  func onboardingUpdate() async {
    let update = Profile.UpdateRequest(
      username: username,
      firstName: firstName,
      lastName: lastName,
      isPrivate: isPrivateProfile,
      showFullName: showFullName,
      isOnboarded: true
    )

    switch await client.profile.update(
      update: update
    ) {
    case .success:
      logger.info("onboarded")
    case let .failure(error):
      logger.error("failed to update profile: \(error.localizedDescription)")
    }
  }

  func updatePrivacySettings() async {
    let update = Profile.UpdateRequest(isPrivate: isPrivateProfile)
    switch await client.profile.update(
      update: update
    ) {
    case .success:
      logger.log("updated privacy settings")
    case let .failure(error):
      logger.error("failed to update settings: \(error.localizedDescription)")
    }
  }

  func updateDisplaySettings() async {
    let update = Profile.UpdateRequest(
      showFullName: showFullName
    )
    switch await client.profile.update(
      update: update
    ) {
    case .success:
      logger.log("updated display settings")
    case let .failure(error):
      logger.error("failed to update profile: \(error.localizedDescription)")
    }
  }

  func getCSVExportName() -> String {
    "\(Config.appName.lowercased())_export_\(Date().customFormat(.fileNameSuffix)).csv"
  }

  func exportData(onError: @escaping (_ error: String) -> Void) async {
    switch await client.profile.currentUserExport() {
    case let .success(csvText):
      csvExport = CSVFile(initialText: csvText)
      showingExporter = true
    case let .failure(error):
      logger.error("failed to export check-in csv: \(error.localizedDescription)")
      onError(error.localizedDescription)
    }
  }
}
