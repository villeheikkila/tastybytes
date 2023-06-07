import SwiftUI

struct FlavorManagementScreen: View {
  @Environment(AppDataManager.self) private var appDataManager
  @Environment(FeedbackManager.self) private var feedbackManager
  @Environment(Router.self) private var router

  var body: some View {
    List {
      ForEach(appDataManager.flavors) { flavor in
        Text(flavor.label)
          .swipeActions {
            ProgressButton("Delete", systemSymbol: .trash, role: .destructive, action: {
              await appDataManager.deleteFlavor(flavor)
            })
          }
      }
    }
    .listStyle(.insetGrouped)
    .navigationBarTitle("Flavors")
    .navigationBarItems(
      trailing: RouterLink("Add flavors", systemSymbol: .plus, sheet: .newFlavor(onSubmit: { newFlavor in
        await appDataManager.addFlavor(name: newFlavor)
      })).labelStyle(.iconOnly)
    )
    #if !targetEnvironment(macCatalyst)
    .refreshable {
      await appDataManager.refreshFlavors()
    }
    #endif
  }
}
