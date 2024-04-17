import Foundation

@MainActor
class GBFSStationInformationProvider: ObservableObject {
  @Published var stations: [StationInformationData] = []

  let client: GBFSStationInformationClient

  func fetchStationInformation() async throws {
    self.stations = try await client.stations
  }

  init(client: GBFSStationInformationClient = GBFSStationInformationClient()) {
    self.client = client
  }
}
