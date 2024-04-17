import SwiftUI
import MapLibre
import MapKit

struct MapView: UIViewRepresentable {

  @Binding var isShownErrorAlert: Bool
  @Binding var alertMessage: String
  @ObservedObject var stationInformationProvider: GBFSStationInformationProvider
  @ObservedObject var stationStatusProvider: GBFSStationStatusProvider

  func makeUIView(context: Context) -> some MLNMapView {
    // MapTilerのキーを取得
    let mapTilerKey = getMapTilerKey()

    // スタイルのURLを定義
    let styleURL = URL(string: "https://api.maptiler.com/maps/jp-mierune-dark/style.json?key=\(mapTilerKey)")

    // Viewを定義
    let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
    mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    mapView.logoView.isHidden = true
    mapView.setCenter(
      CLLocationCoordinate2D(latitude: 35.681111, longitude: 139.766667),
      zoomLevel: 15.0,
      animated: false
    )

    // ユーザーの現在位置を表示
    mapView.showsUserLocation = true

    // DelegateはCoordinatorを指定します
    mapView.delegate = context.coordinator

    return mapView
  }

  func updateUIView(_ uiView: UIViewType, context: Context) {
    /// Viewがアップデートされたときの処理
    print("update")
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(
      isShownErrorAlert: $isShownErrorAlert,
      alertMessage: $alertMessage,
      stationInformationProvider: stationInformationProvider,
      stationStatusProvider: stationStatusProvider,
      control: self
    )
  }

  class Coordinator: NSObject, MLNMapViewDelegate {

    // MARK: - State
    @Binding var isShownErrorAlert: Bool
    @Binding var alertMessage: String
    @ObservedObject var stationInformationProvider: GBFSStationInformationProvider
    @ObservedObject var stationStatusProvider: GBFSStationStatusProvider

    // MARK: - Proerties
    var control: MapView

    init(
      isShownErrorAlert: Binding<Bool>,
      alertMessage: Binding<String>,
      stationInformationProvider: GBFSStationInformationProvider,
      stationStatusProvider: GBFSStationStatusProvider,
      control: MapView
    ) {
      _isShownErrorAlert = isShownErrorAlert
      _alertMessage = alertMessage
      self.stationInformationProvider = stationInformationProvider
      self.stationStatusProvider = stationStatusProvider
      self.control = control
    }

    func mapViewDidFinishLoadingMap(_ mapView: MLNMapView) {
      // マップのローディングが終わったときの処理
      Task {
        do {
          try await stationInformationProvider.fetchStationInformation()
          try await stationStatusProvider.fetchStationStatus()
          drawStations(mapView)
        } catch {
          isShownErrorAlert = true
          alertMessage = "データの取得に失敗しました"
        }
      }
    }

    func drawStations(_ mapView: MLNMapView) {
      guard let style = mapView.style else {
        return
      }

      var features: [MLNPointFeature] = []

      for information in stationInformationProvider.stations {
        let feature = MLNPointFeature()
        feature.coordinate = CLLocationCoordinate2D(latitude: information.lat, longitude: information.lon)

        let status = stationStatusProvider.stations.first(where: {$0.station_id == information.station_id})

        guard let status = status else {
          continue
        }

        feature.attributes = [
          "bike_available": status.num_bikes_available
        ]

        features.append(feature)
      }

      let source = createStationSource(style, features: features);

      let circleLayer = createStationCircleLayer(source)
      let textLayer = createStationTextLayer(source)

      style.addLayer(circleLayer)
      style.addLayer(textLayer)
    }

    func createStationSource(_ style: MLNStyle, features: [MLNPointFeature]) -> MLNSource {
      let source = MLNShapeSource(identifier: "bike-station-source", features: features)
      style.addSource(source)

      return source
    }

    func createStationCircleLayer(_ source: MLNSource) -> MLNCircleStyleLayer {

      let stops: [NSNumber: UIColor] = [
        0: .red,
        1: .yellow,
        3: .yellow,
        4: .green,
      ]

      let circleLayer = MLNCircleStyleLayer(identifier: "station-circle-layer", source: source)
      circleLayer.circleRadius = NSExpression(forConstantValue: 14)
      circleLayer.circleColor = NSExpression(
        format: "mgl_interpolate:withCurveType:parameters:stops:(bike_available, 'linear', nil, %@)",
        stops
      )
      return circleLayer
    }

    func createStationTextLayer(_ source: MLNSource) -> MLNSymbolStyleLayer {
      let textLayer = MLNSymbolStyleLayer(identifier: "station-text-layer", source: source)
      textLayer.text = NSExpression(forKeyPath: "bike_available")
      textLayer.textColor = NSExpression(forConstantValue: UIColor.black)

      return textLayer
    }

    /// 現在位置が変更されたときの処理
    /// - Parameters:
    ///   - mapView: MapLibreのMapView
    ///   - userLocation: ユーザーの現在位置
    func mapView(_ mapView: MLNMapView, didUpdate userLocation: MLNUserLocation?) {

      // ユーザーの位置情報を取得
      guard let location = userLocation?.location else {
        return
      }

      let lat = location.coordinate.latitude
      let lon = location.coordinate.longitude

      // 地図の中心をユーザーの位置情報に移動
      mapView.setCenter(
        CLLocationCoordinate2D(latitude: lat, longitude: lon),
        animated: false
      )
    }
  }

  /// MapTilerのキーを取得します
  /// - Returns: MapTilerのAPIキー
  func getMapTilerKey() -> String {
    let key = Bundle.main.object(forInfoDictionaryKey: "MapTilerKey") as? String

    guard let key = key else {
      preconditionFailure("Failed to read MapTiler Key")
    }

    return key
  }
}
