import Components

import Extensions
import Logging
import Models
import Repositories
import SwiftUI

struct ProfileWishlistScreen: View {
    private let logger = Logger(label: "ProfileWishlistScreen")
    @Environment(Repository.self) private var repository
    @Environment(FeedbackModel.self) private var feedbackModel
    @State private var state: ScreenState = .loading
    @State private var products: [Product.Joined] = []
    @State private var searchTerm = ""

    let profile: Profile.Saved

    var body: some View {
        List(products) { product in
            RouterLink(open: .screen(.product(product.id))) {
                ProductView(product: product)
            }
            .swipeActions(allowsFullSwipe: true) {
                AsyncButton(
                    "labels.delete",
                    systemImage: "xmark",
                    role: .destructive,
                    action: {
                        await removeFromWishlist(product: product)
                    }
                )
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchTerm, placement: .navigationBarDrawer(displayMode: .always))
        .refreshable {
            await loadProducts()
        }
        .overlay {
            if state.isPopulated {
                if products.isEmpty {
                    ContentUnavailableView {
                        Label("wishlist.empty.title", systemImage: "list.star")
                    }
                }
            } else {
                ScreenStateOverlayView(state: state) {
                    await loadProducts()
                }
            }
        }
        .navigationTitle("wishlist.navigationTitle")
        .initialTask {
            await loadProducts()
        }
    }

    private func removeFromWishlist(product: Product.Joined) async {
        do {
            try await repository.product.removeFromWishlist(productId: product.id)
            feedbackModel.trigger(.notification(.success))
            withAnimation {
                products.remove(object: product)
            }
        } catch {
            guard !error.isCancelled else { return }
            logger.error("Removing from wishlist failed. Error: \(error) (\(#file):\(#line))")
        }
    }

    private func loadProducts() async {
        do {
            let wishlist = try await repository.product.getWishlistItems(profileId: profile.id)
            withAnimation {
                products = wishlist.map(\.product)
                state = .populated
            }
        } catch {
            guard !error.isCancelled else { return }
            if state != .populated {
                state = .error(error)
            }
            logger
                .error(
                    "Error occured while loading wishlist items. Description: \(error.localizedDescription). Error: \(error) (\(#file):\(#line))"
                )
        }
    }
}
