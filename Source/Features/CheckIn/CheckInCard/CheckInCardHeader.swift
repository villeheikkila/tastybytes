import Components
import EnvironmentModels
import Models
import SwiftUI

struct CheckInCardHeader: View {
    @Environment(\.checkInCardLoadedFrom) private var checkInCardLoadedFrom
    let profile: Profile
    let location: Location?

    var body: some View {
        RouterLink(open: .screen(.profile(profile))) {
            HStack {
                Avatar(profile: profile)
                    .avatarSize(.large)
                Text(profile.preferredName)
                    .font(.caption).bold()
                    .foregroundColor(.primary)
                Spacer()
                if let location {
                    RouterLink(open: .screen(.location(location))) {
                        Text(location.formatted(.withEmoji))
                            .font(.caption).bold()
                            .foregroundColor(.primary)
                            .contentShape(.rect)
                    }
                    .routerLinkDisabled(checkInCardLoadedFrom.isLoadedFromLocation(location))
                }
            }
            .contentShape(.rect)
        }
        .routerLinkDisabled(checkInCardLoadedFrom.isLoadedFromProfile(profile))
    }
}
