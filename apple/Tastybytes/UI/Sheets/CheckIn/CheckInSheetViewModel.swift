import PhotosUI
import SwiftUI

extension CheckInSheet {
  enum Focusable {
    case review
  }

  enum Action {
    case create
    case update
  }

  @MainActor
  class ViewModel: ObservableObject {
    private let logger = getLogger(category: "CheckInSheet")
    let client: Client
    @Published var product: Product.Joined
    @Published var editCheckIn: CheckIn?
    @Published var showCamera = false
    @Published var review: String = ""
    @Published var rating: Double = 0
    @Published var manufacturer: Company?
    @Published var servingStyles = [ServingStyle]()
    @Published var servingStyle: ServingStyle?
    @Published var taggedFriends = [Profile]()
    @Published var pickedFlavors = [Flavor]()
    @Published var location: Location?
    @Published var purchaseLocation: Location?
    @Published var checkInAt: Date = .now
    @Published var image: UIImage? {
      didSet {
        Task {
          if let image, let hash = image.resize(to: 100)?
            .blurHash(numberOfComponents: (5, 5))
          {
            self.blurHash = "\(image.size.width):\(image.size.height):::\(hash)"
          }
        }
      }
    }

    var blurHash: String?

    init(_ client: Client, product: Product.Joined, editCheckIn: CheckIn?) {
      self.client = client
      self.product = product

      if let editCheckIn {
        self.editCheckIn = editCheckIn
        review = editCheckIn.review.orEmpty
        rating = editCheckIn.rating ?? 0
        manufacturer = editCheckIn.variant?.manufacturer
        servingStyle = editCheckIn.servingStyle
        taggedFriends = editCheckIn.taggedProfiles
        pickedFlavors = editCheckIn.flavors
        location = editCheckIn.location
        purchaseLocation = editCheckIn.purchaseLocation
        checkInAt = editCheckIn.checkInAt ?? Date.now
      }
    }

    func setImageFromCamera(_ image: UIImage) async {
      Task {
        self.image = image
        self.showCamera = false
      }
    }

    func setImageFromPicker(pickedImage: UIImage) {
      Task {
        self.image = pickedImage
      }
    }

    func updateCheckIn(_ onUpdate: @escaping (_ checkIn: CheckIn) async -> Void) async {
      guard let editCheckIn else { return }
      let updateCheckInParams = CheckIn.UpdateRequest(
        checkIn: editCheckIn,
        product: product,
        review: review,
        taggedFriends: taggedFriends,
        servingStyle: servingStyle,
        manufacturer: manufacturer,
        flavors: pickedFlavors,
        rating: rating,
        location: location,
        purchaseLocation: purchaseLocation,
        blurHash: blurHash,
        checkInAt: checkInAt
      )

      switch await client.checkIn.update(updateCheckInParams: updateCheckInParams) {
      case let .success(updatedCheckIn):
        await uploadImage(checkIn: updatedCheckIn)
        await onUpdate(updatedCheckIn)
      case let .failure(error):
        logger.error("failed to update check-in '\(editCheckIn.id)': \(error.localizedDescription)")
      }
    }

    func createCheckIn(_ onCreation: @escaping (_ checkIn: CheckIn) async -> Void) async {
      let newCheckParams = CheckIn.NewRequest(
        product: product,
        review: review,
        taggedFriends: taggedFriends,
        servingStyle: servingStyle,
        manufacturer: manufacturer,
        flavors: pickedFlavors,
        rating: rating,
        location: location,
        purchaseLocation: purchaseLocation,
        blurHash: blurHash,
        checkInAt: checkInAt
      )

      switch await client.checkIn.create(newCheckInParams: newCheckParams) {
      case let .success(newCheckIn):
        await uploadImage(checkIn: newCheckIn)
        await onCreation(newCheckIn)
      case let .failure(error):
        logger.error("failed to create check-in: \(error.localizedDescription)")
      }
    }

    func uploadImage(checkIn: CheckIn) async {
      guard let data = image?.jpegData(compressionQuality: 0.1) else { return }
      switch await client.checkIn.uploadImage(id: checkIn.id, data: data, userId: checkIn.profile.id) {
      case let .failure(error):
        logger.error("failed to uplaod image to check-in '\(checkIn.id)': \(error.localizedDescription)")
      default:
        break
      }
    }
  }
}
