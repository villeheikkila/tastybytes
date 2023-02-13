import PhotosUI
import SwiftUI

extension CheckInSheetView {
  enum Focusable {
    case review
  }

  enum Action {
    case create
    case update
  }

  enum Sheet: Identifiable {
    var id: Self { self }
    case manufacturer
    case friends
    case flavors
    case location
    case photoPicker
  }

  @MainActor class ViewModel: ObservableObject {
    private let logger = getLogger(category: "CheckInSheetView")
    let client: Client
    @Published var product: Product.Joined
    @Published var editCheckIn: CheckIn?
    @Published var selectedItem: PhotosPickerItem?
    @Published var activeSheet: Sheet?
    @Published var showCamera = false
    @Published var review: String = ""
    @Published var rating: Double = 0
    @Published var manufacturer: Company?
    @Published var servingStyleName: ServingStyle.Name = .none {
      // TODO: Investigate if this can be avoided by passing ServingStyle directly to the picker
      didSet {
        servingStyle = servingStyles.first(where: { $0.name == servingStyleName })
      }
    }

    @Published var servingStyles = [ServingStyle]()
    @Published var servingStyle: ServingStyle?
    @Published var taggedFriends = [Profile]()
    @Published var pickedFlavors = [Flavor]()
    @Published var location: Location?
    @Published var image: UIImage?

    init(_ client: Client, product: Product.Joined, editCheckIn: CheckIn?) {
      self.client = client
      self.product = product

      if let editCheckIn {
        self.editCheckIn = editCheckIn
        review = editCheckIn.review.orEmpty
        rating = editCheckIn.rating ?? 0
        manufacturer = editCheckIn.variant?.manufacturer
        servingStyleName = editCheckIn.servingStyle?.name ?? ServingStyle.Name.none
        taggedFriends = editCheckIn.taggedProfiles
        pickedFlavors = editCheckIn.flavors
        location = editCheckIn.location
      }
    }

    func setActiveSheet(_ sheet: Sheet) {
      activeSheet = sheet
    }

    func setLocation(_ location: Location) {
      self.location = location
    }

    func setManufacturer(_ company: Company) {
      manufacturer = company
    }

    func setImageFromCamera(_ image: UIImage) {
      Task {
        self.image = image
        self.showCamera = false
      }
    }

    func setImageFromPicker(pickedImage: UIImage) {
      image = pickedImage
    }

    func updateCheckIn(_ onUpdate: @escaping (_ checkIn: CheckIn) -> Void) {
      if let editCheckIn {
        let updateCheckInParams = CheckIn.UpdateRequest(
          checkIn: editCheckIn,
          product: product,
          review: review,
          taggedFriends: taggedFriends,
          servingStyle: servingStyle,
          manufacturer: manufacturer,
          flavors: pickedFlavors,
          rating: rating,
          location: location
        )

        Task {
          switch await client.checkIn.update(updateCheckInParams: updateCheckInParams) {
          case let .success(updatedCheckIn):
            uploadImage(checkIn: updatedCheckIn)
            onUpdate(updatedCheckIn)
          case let .failure(error):
            logger.error("failed to update check-in '\(editCheckIn.id)': \(error.localizedDescription)")
          }
        }
      }
    }

    func createCheckIn(_ onCreation: @escaping (_ checkIn: CheckIn) -> Void) {
      let newCheckParams = CheckIn.NewRequest(
        product: product,
        review: review,
        taggedFriends: taggedFriends,
        servingStyle: servingStyle,
        manufacturer: manufacturer,
        flavors: pickedFlavors,
        rating: rating,
        location: location
      )

      Task {
        switch await client.checkIn.create(newCheckInParams: newCheckParams) {
        case let .success(newCheckIn):
          uploadImage(checkIn: newCheckIn)
          onCreation(newCheckIn)
        case let .failure(error):
          logger.error("failed to create check-in: \(error.localizedDescription)")
        }
      }
    }

    func uploadImage(checkIn: CheckIn) {
      Task {
        if let data = image?.jpegData(compressionQuality: 0.1) {
          switch await client.checkIn.uploadImage(id: checkIn.id, data: data, userId: checkIn.profile.id) {
          case let .failure(error):
            logger.error("failed to uplaod image to check-in '\(checkIn.id)': \(error.localizedDescription)")
          default:
            break
          }
        }
      }
    }

    func loadInitialData() {
      Task {
        switch await client.category.getServingStylesByCategory(categoryId: product.category.id) {
        case let .success(categoryServingStyles):
          self.servingStyles = categoryServingStyles.servingStyles
        case let .failure(error):
          logger
            .error(
              "failed to load serving styles by category '\(self.product.category.id)': \(error.localizedDescription)"
            )
        }
      }
    }
  }
}
