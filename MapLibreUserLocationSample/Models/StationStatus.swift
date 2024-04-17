import Foundation

struct StationStatus: Codable {
  let ttl: Int
  let data: StationStatusData
  let version: String
  let last_updated: Int64
}

struct StationStatusData: Codable {
  let stations: [StationStatusStation]
}

struct StationStatusStation: Codable {
  let is_installed: Bool
  let is_renting: Bool
  let is_returning: Bool
  let station_id: String
  let num_bikes_available: Int
  let num_docks_available: Int
}
