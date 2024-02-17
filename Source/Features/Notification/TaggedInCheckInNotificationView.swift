import Components
import Models
import SwiftUI

struct TaggedInCheckInNotificationView: View {
    let checkIn: CheckIn

    var body: some View {
        RouterLink(screen: .checkIn(checkIn)) {
            HStack {
                Avatar(profile: checkIn.profile, size: 32)
                Text(
                    "notification.taggedCheckIn.userTaggedYou \(checkIn.profile.preferredName) \(checkIn.product.formatted(.full))"
                )
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
