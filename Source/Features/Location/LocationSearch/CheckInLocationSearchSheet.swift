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

struct CheckInLocationSearchSheet: View {
    private let logger = Logger(category: "CheckInLocationSearchSheet")
    @Environment(Router.self) private var router
    @Environment(Repository.self) private var repository
    @Environment(FeedbackEnvironmentModel.self) private var feedbackEnvironmentModel
    @Environment(LocationEnvironmentModel.self) private var locationEnvironmentModel
    @Environment(\.dismiss) private var dismiss
    @State private var state: ScreenState = .loading
    @State private var storeLocationTask: Task<Void, Never>?
    @State private var searchResults = [Location]()
    @State private var recentLocations = [Location]()
    @State private var nearbyLocations = [Location]()
    @State private var searchTerm = ""
    @Binding private var initialLocation: Location?
    @State private var currentLocation: CLLocation?

    let category: Location.RecentLocation
    let title: LocalizedStringKey
    let onSelect: (_ location: Location) -> Void

    init(category: Location.RecentLocation, title: LocalizedStringKey, initialLocation: Binding<Location?>, onSelect: @escaping (_ location: Location) -> Void) {
        self.title = title
        self.onSelect = onSelect
        self.category = category
        _initialLocation = initialLocation
    }

    var hasSearched: Bool {
        !searchTerm.isEmpty || initialLocation != nil
    }

    private var centerCoordinate: CLLocationCoordinate2D {
        initialLocation?.location?.coordinate ?? currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384)
    }

    private let radius: CLLocationDistance = 2000

    var body: some View {
        List {
            if state == .populated {
                content
            }
        }
        .scrollContentBackground(.hidden)
        .searchable(text: $searchTerm)
        .overlay {
            ScreenStateOverlayView(state: state, errorDescription: "") {
                await loadInitialData()
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            if initialLocation != nil {
                InitialLocationOverlay(initialLocation: $initialLocation)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .task(id: searchTerm, milliseconds: 500) { [searchTerm] in
            guard initialLocation == nil else { return }
            guard !searchTerm.isEmpty else {
                searchResults = []
                return
            }
            await search(for: searchTerm, centerCoordinate: centerCoordinate)
        }
        .task {
            await loadInitialData()
        }
    }

    @ViewBuilder private var content: some View {
        if hasSearched {
            ForEach(searchResults) { location in
                LocationRow(location: location, currentLocation: currentLocation, onSelect: storeLocation)
            }
        } else {
            if !recentLocations.isEmpty {
                Section("location.recent") {
                    ForEach(recentLocations) { location in
                        LocationRow(location: location, currentLocation: currentLocation, onSelect: storeLocation)
                    }
                }
                .headerProminence(.increased)
            }
            if locationEnvironmentModel.hasAccess, !recentLocations.isEmpty {
                Section("location.nearBy") {
                    ForEach(nearbyLocations) { location in
                        LocationRow(location: location, currentLocation: currentLocation, onSelect: storeLocation)
                    }
                }
                .headerProminence(.increased)
            }
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarDismissAction()
    }

    func search(for query: String?, centerCoordinate: CLLocationCoordinate2D) async {
        if let query {
            do {
                searchResults = try await searchLocationsNatural(query: query, center: centerCoordinate, radius: radius)
            } catch {
                logger.error("Error occured while looking up locations: \(error)")
            }
        } else if let initialCoordinate = initialLocation?.location?.coordinate {
            do {
                searchResults = try await searchLocations(center: initialCoordinate, radius: radius)
            } catch {
                logger.error("Error occured while looking up locations: \(error)")
            }
        }
    }

   private func storeLocation(_ location: Location) {
        guard storeLocationTask == nil else { return }
        defer { storeLocationTask = nil }
        storeLocationTask = Task {
            do { let savedLocation = try await repository.location.insert(location: location)
                onSelect(savedLocation)
                dismiss()
            } catch {
                guard !error.isCancelled else { return }
                router.open(.alert(.init()))
                logger.error("Saving location \(location.name) failed. Error: \(error) (\(#file):\(#line))")
            }
        }
    }

    private nonisolated func searchLocationsNatural(query: String?, center: CLLocationCoordinate2D, radius: CLLocationDistance)
        async throws -> [Location]
    {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = .init(center: center, latitudinalMeters: radius, longitudinalMeters: radius)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems.map { Location(mapItem: $0) }
    }

    private nonisolated func searchLocations(center: CLLocationCoordinate2D, radius: CLLocationDistance)
        async throws -> [Location]
    {
        let request = MKLocalPointsOfInterestRequest(center: center, radius: radius)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems.map { Location(mapItem: $0) }
    }

    private func loadInitialData() async {
        if initialLocation != nil {
            await search(for: nil, centerCoordinate: centerCoordinate)
        }
        currentLocation = await locationEnvironmentModel.getCurrentLocation()
        let coordinate = currentLocation?.coordinate ?? centerCoordinate
        async let recentLocationsPromise = repository.location.getRecentLocations(category: category)
        async let suggestionsPromise = repository.location.getSuggestions(location: .init(coordinate: coordinate))
        var errors = [Error]()
        do {
            let (recentLocations, nearbyLocations) = try await (recentLocationsPromise, suggestionsPromise)
            self.recentLocations = recentLocations
            self.nearbyLocations = nearbyLocations
        } catch {
            errors.append(error)
            logger.error("Failed to load location suggestions. Error: \(error) (\(#file):\(#line))")
        }
        state = .getState(errors: errors, withHaptics: false, feedbackEnvironmentModel: feedbackEnvironmentModel)
    }
}

struct LocationRow: View {
    let location: Location
    let currentLocation: CLLocation?
    let onSelect: (_ location: Location) -> Void

    var distance: Measurement<UnitLength>? {
        guard let currentLocation, let clLocation = location.location else { return nil }
        let distanceInMeters = currentLocation.distance(from: clLocation)
        return .init(value: distanceInMeters, unit: UnitLength.meters)
    }

    var body: some View {
        HStack {
            if let coordinate = location.location?.coordinate {
                MapThumbnail(location: location, coordinate: coordinate, distance: distance)
            }
            Button(action: {
                onSelect(location)
            }) {
                VStack(alignment: .leading) {
                    Text(location.name)
                    if let title = location.title {
                        Text(title)
                            .foregroundColor(.secondary)
                    }
                    if let distance {
                        Text(distance, format: .measurement(width: .narrow))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
    }
}

struct InitialLocationOverlay: View {
    @Binding var initialLocation: Location?

    var body: some View {
        if let coordinate = initialLocation?.location?.coordinate {
            HStack {
                Text("location.initialLocationOverlay.description \(coordinate.latitude.formatted(.number.precision(.fractionLength(2)))) \(coordinate.longitude.formatted(.number.precision(.fractionLength(2))))")
                Spacer()
                CloseButtonView {
                    initialLocation = nil
                }
                .labelStyle(.iconOnly)
                .imageScale(.large)
            }
            .padding()
            .background(.thinMaterial)
        }
    }
}
