import Foundation

class GBFSStationStatusClient {

  var stations: [StationStatusData] {
    get async throws {
      let data = try await downloader.httpData(from: feedURL)
      let information = try decoder.decode(StationStatus.self, from: data)
      return information.stations
    }
  }

  private let feedURL = URL(string: "https://api-public.odpt.org/api/v4/gbfs/hellocycling/station_status.json")!
  private let downloader: any HTTPDataDownloader
  private lazy var decoder = JSONDecoder()

  init(downloader: any HTTPDataDownloader = URLSession.shared) {
    self.downloader = downloader
  }
}
