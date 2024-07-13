import Foundation
import Models

public protocol ProfileRepository: Sendable {
    func getById(id: UUID) async -> Result<Profile, Error>
    func getCurrentUser() async throws -> Profile.Extended
    func update(update: Profile.UpdateRequest) async -> Result<Profile.Extended, Error>
    func currentUserExport() async -> Result<String, Error>
    func search(searchTerm: String, currentUserId: UUID?) async -> Result<[Profile], Error>
    func uploadAvatar(userId: UUID, data: Data) async -> Result<ImageEntity, Error>
    func deleteCurrentAccount() async throws
    func updateSettings(update: ProfileSettings.UpdateRequest) async -> Result<ProfileSettings, Error>
    func getContributions(id: UUID) async -> Result<Profile.Contributions, Error>
    func getCategoryStatistics(userId: UUID) async -> Result<[CategoryStatistics], Error>
    func getSubcategoryStatistics(userId: UUID, categoryId: Int) async -> Result<[SubcategoryStatistics], Error>
    func getTimePeriodStatistics(userId: UUID, timePeriod: StatisticsTimePeriod) async
        -> Result<TimePeriodStatistic, Error>
    func checkIfUsernameIsAvailable(username: String) async -> Result<Bool, Error>
    func getNumberOfCheckInsByDay(_ request: NumberOfCheckInsByDayRequest) async -> Result<[CheckInsPerDay], Error>
    func getNumberOfCheckInsByLocation(userId: UUID) async -> Result<[ProfileTopLocations], Error>
}
