import Components
import CoreLocation
import EnvironmentModels
import Extensions
import Foundation
import MapKit
import Models
import OSLog
import Repositories
import SwiftUI

// HACK: Remove when no longer necessary
extension MKLocalSearch.Response: @unchecked Sendable {}

@MainActor
struct LocationSearchSheet: View {
    private let logger = Logger(category: "LocationSearchView")
    @Environment(Repository.self) private var repository
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @Environment(PermissionEnvironmentModel.self) private var permissionEnvironmentModel
    @Environment(LocationEnvironmentModel.self) private var locationEnvironmentModel
    @State private var searchResults = [Location]()
    @State private var recentLocations = [Location]()
    @State private var nearbyLocations = [Location]()
    @State private var currentLocation: CLLocation?
    @State private var searchText = ""
    @State private var alertError: AlertError?

    @Environment(\.dismiss) private var dismiss

    let category: Location.RecentLocation
    let title: String
    let onSelect: (_ location: Location) -> Void
    let initialLocation: CLLocationCoordinate2D?

    init(category: Location.RecentLocation, title: String, initialLocation: CLLocationCoordinate2D?, onSelect: @escaping (_ location: Location) -> Void) {
        self.title = title
        self.onSelect = onSelect
        self.category = category
        self.initialLocation = initialLocation
    }

    var hasSearched: Bool {
        !searchText.isEmpty || initialLocation != nil
    }

    private let radius: CLLocationDistance = 2000

    func search(for query: String?) {
        let request = MKLocalSearch.Request()
        if let query {
            request.naturalLanguageQuery = query
        }
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(center: initialLocation ?? CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384),
                                            latitudinalMeters: radius,
                                            longitudinalMeters: radius)

        Task { @MainActor in
            let search = MKLocalSearch(request: request)
            let response = try? await search.start()
            let rawResults = response?.mapItems ?? []
            searchResults = rawResults.map { Location(mapItem: $0) }
        }
    }

    var body: some View {
        List {
            if !recentLocations.isEmpty, !hasSearched {
                Section("Recent locations") {
                    ForEach(recentLocations) { location in
                        LocationRow(location: location, currentLocation: currentLocation, onSelect: onSelect)
                    }
                }
            }
            if locationEnvironmentModel.hasAccess, !recentLocations.isEmpty, !hasSearched {
                Section("Nearby locations") {
                    ForEach(nearbyLocations) { location in
                        LocationRow(location: location, currentLocation: currentLocation, onSelect: onSelect)
                    }
                }
            }
            if hasSearched {
                ForEach(searchResults) { location in
                    LocationRow(location: location, currentLocation: currentLocation, onSelect: onSelect)
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle(title)
        .toolbar {
            toolbarContent
        }
        .onChange(of: searchText, debounceTime: 0.5, perform: { _ in
            search(for: searchText)
        })
        .task {
            await getRecentLocations()
        }
        .task {
            await locationEnvironmentModel.updateLocation()
        }
        .task {
            if initialLocation != nil {
                search(for: nil)
            }
        }
        .alertError($alertError)
        .onChange(of: locationEnvironmentModel.location) { _, latestLocation in
            guard nearbyLocations.isEmpty else { return }
            currentLocation = latestLocation
            Task { await getSuggestions(latestLocation) }
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarDismissAction()
    }

    func getRecentLocations() async {
        switch await repository.location.getRecentLocations(category: category) {
        case let .success(recentLocations):
            withAnimation {
                self.recentLocations = recentLocations
            }
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Failed to load recemt locations. Error: \(error) (\(#file):\(#line))")
        }
    }

    func getSuggestions(_ location: CLLocation?) async {
        guard let location else { return }
        switch await repository.location.getSuggestions(location: Location.SuggestionParams(location: location)) {
        case let .success(nearbyLocations):
            withAnimation {
                self.nearbyLocations = nearbyLocations
            }
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Failed to load location suggestions. Error: \(error) (\(#file):\(#line))")
        }
    }
}

@MainActor
struct LocationRow: View {
    private let logger = Logger(category: "LocationSearchView")
    @Environment(Repository.self) private var repository
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @Environment(\.dismiss) private var dismiss
    @State private var alertError: AlertError?

    let location: Location
    let currentLocation: CLLocation?
    let onSelect: (_ location: Location) -> Void

    var distance: Measurement<UnitLength>? {
        guard let currentLocation, let clLocation = location.location else { return nil }
        let distanceInMeters = currentLocation.distance(from: clLocation)
        return .init(value: distanceInMeters, unit: UnitLength.meters)
    }

    var body: some View {
        ProgressButton(action: {
            await storeLocation(location)
        }, label: {
            VStack(alignment: .leading) {
                Text(location.name)
                if let title = location.title {
                    Text(title)
                        .foregroundColor(.secondary)
                }
                if let distance {
                    Text("Distance: \(distance, format: .measurement(width: .narrow))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        })
        .alertError($alertError)
    }

    func storeLocation(_ location: Location) async {
        switch await repository.location.insert(location: location) {
        case let .success(savedLocation):
            onSelect(savedLocation)
            dismiss()
        case let .failure(error):
            guard !error.isCancelled else { return }
            alertError = .init()
            logger.error("Saving location \(location.name) failed. Error: \(error) (\(#file):\(#line))")
        }
    }
}
