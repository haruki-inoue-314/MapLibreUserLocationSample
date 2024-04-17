import Foundation

@MainActor
class GBFSStationStatusProvider: ObservableObject {
  @Published var stations: [StationStatusData] = []

  let client: GBFSStationStatusClient

  func fetchStationStatus() async throws {
    self.stations = try await client.stations
  }

  init(client: GBFSStationStatusClient = GBFSStationStatusClient()) {
    self.client = client
  }
}

