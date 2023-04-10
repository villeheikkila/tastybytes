import SwiftUI

struct ServingStyleManagementSheet: View {
  @StateObject private var viewModel: ViewModel
  @EnvironmentObject private var hapticManager: HapticManager
  @Environment(\.dismiss) private var dismiss
  @Binding var pickedServingStyles: [ServingStyle]
  let onSelect: (_ servingStyle: ServingStyle) -> Void

  init(
    _ client: Client,
    pickedServingStyles: Binding<[ServingStyle]>,
    onSelect: @escaping (_ servingStyle: ServingStyle) -> Void
  ) {
    _viewModel = StateObject(wrappedValue: ViewModel(client))
    _pickedServingStyles = pickedServingStyles
    self.onSelect = onSelect
  }

  var body: some View {
    List {
      ForEach(viewModel.servingStyles) { servingStyle in
        Button(action: { onSelect(servingStyle) }, label: {
          HStack {
            Text(servingStyle.label)
            Spacer()
            if pickedServingStyles.contains(servingStyle) {
              Label("Picked serving style", systemImage: "checkmark")
                .labelStyle(.iconOnly)
            }
          }
        })
        .swipeActions {
          Button(action: { viewModel.editServingStyle = servingStyle }, label: {
            Label("Edit", systemImage: "pencil")
          }).tint(.yellow)
          Button(role: .destructive, action: { viewModel.toDeleteServingStyle = servingStyle }, label: {
            Label("Delete", systemImage: "trash")
          })
        }
      }
      Section {
        TextField("Name", text: $viewModel.newServingStyleName)
        ProgressButton("Create") {
          await viewModel.createServingStyle()
        }
        .disabled(!viewModel.newServingStyleName.isValidLength(.normal))
      } header: {
        Text("Add new serving style")
      }
    }
    .navigationBarTitle("Pick Serving Style")
    .navigationBarItems(trailing: Button(role: .cancel, action: { dismiss() }, label: {
      Text("Done").bold()
    }))
    .alert("Edit Serving Style", isPresented: $viewModel.showEditServingStyle, actions: {
      TextField("TextField", text: $viewModel.servingStyleName)
      Button("Cancel", role: .cancel, action: {})
      Button("Edit", action: {
        viewModel.saveEditServingStyle()
      })
    })
    .confirmationDialog(
      "Are you sure you want to delete the serving style? The serving style information for affected check-ins will be permanently lost",
      isPresented: $viewModel.showDeleteServingStyleConfirmation,
      titleVisibility: .visible,
      presenting: viewModel.toDeleteServingStyle
    ) { presenting in
      Button(
        "Delete \(presenting.name)",
        role: .destructive,
        action: {
          viewModel.deleteServingStyle(onDelete: {
            hapticManager.trigger(.notification(.success))
          })
        }
      )
    }
    .task {
      await viewModel.getAllServingStyles()
    }
  }
}
