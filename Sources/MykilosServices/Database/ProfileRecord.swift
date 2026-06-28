import Foundation
import GRDB
import MykilosKit

// MARK: - ProfileRecord
// GRDB-Persistenz des lokalen Nutzerprofils. Genau EINE Zeile mit fixer
// id = "local" — bewusste V1-Vereinfachung gegenüber dem Team-Identitätsmodell.
// Datum als timeIntervalSince1970 (Double), konsistent mit notes/auditEntries.
struct ProfileRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "userProfile"
    static let localID = "local"

    var id: String
    var displayName: String
    var role: String
    var updatedAt: Double
    var clockodoUserID: String?
    var googleDomain: String?

    init(from profile: UserProfile) {
        self.id = Self.localID
        self.displayName = profile.displayName
        self.role = profile.role
        self.updatedAt = profile.updatedAt.timeIntervalSince1970
        self.clockodoUserID = profile.clockodoUserID
        self.googleDomain = profile.googleDomain
    }

    func toDomain() -> UserProfile {
        UserProfile(
            displayName: displayName,
            role: role,
            updatedAt: Date(timeIntervalSince1970: updatedAt),
            clockodoUserID: clockodoUserID,
            googleDomain: googleDomain
        )
    }
}
