import Foundation

struct StationInformation: Codable {
  let ttl: Int
  let data: StationInformationData
  let version: String
  let last_updated: Int64
}

struct StationInformationData: Codable {
  let stations: [StationInformationStation]
}

struct StationInformationStation: Codable {
  let lat: Double
  let lon: Double
  let name: String
  let address: String?
  let station_id: String
  let vehicle_capacity: String?
}
