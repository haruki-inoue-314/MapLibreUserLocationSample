import Foundation

@MainActor
class GBFSStationIndormationProvider: ObservableObject {
  @Published var stations: [StationInformationData] = []

  let client: GBFSStationInformationClient

  func fetchStationInformation() async throws {
    self.stations = try await client.stations
  }

  init(client: GBFSStationInformationClient = GBFSStationInformationClient()) {
    self.client = client
  }
}
