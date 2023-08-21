import EnvironmentModels
import Models
import SwiftUI

struct AppIconScreen: View {
    @Environment(ProfileEnvironmentModel.self) private var profileEnvironmentModel
    @State private var appIcons = [AppIcon.ramune, AppIcon.cola, AppIcon.energyDrink, AppIcon.juice, AppIcon.kombucha]
    @State private var selection: AppIcon?

    var body: some View {
        List(appIcons, id: \.self, selection: $selection) { appIcon in
            HStack(spacing: 12) {
                Image(appIcon.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                    .accessibilityLabel("\(appIcon.label) app icon")

                Text(appIcon.label)
                    .fontWeight(.medium)

                Spacer()

                Label("Selected", systemSymbol: .checkmark)
                    .labelStyle(.iconOnly)
                    .opacity(appIcon == selection ? 1 : 0)
            }
            .padding(4)
        }
        .navigationBarTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selection) { _, icon in
            if let icon, selection != getCurrentAppIcon() {
                UIApplication.shared.setAlternateIconName(icon == AppIcon.ramune ? nil : icon.rawValue)
                profileEnvironmentModel.appIcon = icon
            }
        }
        .onAppear {
            selection = getCurrentAppIcon()
        }
    }
}
