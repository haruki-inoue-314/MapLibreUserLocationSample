import Foundation

class GBFSStationInformationClient {
  
  var stations: [StationInformationStation] {
    get async throws {
      let data = try await downloader.httpData(from: feedURL)
      let information = try decoder.decode(StationInformation.self, from: data)
      return information.data.stations
    }
  }
  
  private let feedURL = URL(string: "https://api-public.odpt.org/api/v4/gbfs/hellocycling/station_information.json")!
  private let downloader: any HTTPDataDownloader
  private lazy var decoder = JSONDecoder()
  
  init(downloader: any HTTPDataDownloader = URLSession.shared) {
    self.downloader = downloader
  }
}
