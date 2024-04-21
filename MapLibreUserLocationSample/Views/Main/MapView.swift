import SwiftUI
import MapLibre
import MapKit

struct MapView: UIViewRepresentable {

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
    guard
      let style = uiView.style,
      let source = style.source(withIdentifier: "bike-station-source") as? MLNShapeSource
    else {
      return
    }

    if (stationInformationProvider.stations.isEmpty || stationStatusProvider.stations.isEmpty) {
      return
    }

    source.shape = MLNShapeCollectionFeature(shapes: createFeatures(uiView as MLNMapView))
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(
      stationInformationProvider: stationInformationProvider,
      stationStatusProvider: stationStatusProvider,
      control: self
    )
  }

  class Coordinator: NSObject, MLNMapViewDelegate {

    // MARK: - State
    @ObservedObject var stationInformationProvider: GBFSStationInformationProvider
    @ObservedObject var stationStatusProvider: GBFSStationStatusProvider

    // MARK: - Proerties
    var control: MapView

    // MARK: - Initialize
    init(
      stationInformationProvider: GBFSStationInformationProvider,
      stationStatusProvider: GBFSStationStatusProvider,
      control: MapView
    ) {
      self.stationInformationProvider = stationInformationProvider
      self.stationStatusProvider = stationStatusProvider
      self.control = control
    }

    /// マップのローディングが終わったときの処理
    /// - Parameter mapView: MapView
    func mapViewDidFinishLoadingMap(_ mapView: MLNMapView) {
      print("mapViewDidFinishLoadingMap")
      drawStations(mapView)
    }

    /// 地図に自転車のポートを表示します
    /// - Parameter mapView: MapView
    func drawStations(_ mapView: MLNMapView) {

      guard let style = mapView.style else {
        return
      }

      let source = createStationSource(style, features: control.createFeatures(mapView));

      let circleLayer = createStationCircleLayer(source)
      let textLayer = createStationTextLayer(source)

      style.addLayer(circleLayer)
      style.addLayer(textLayer)
    }

    /// 地図に表示する自転車ポートのソースを作成します
    /// - Parameters:
    ///   - style: MapViewのStyle
    ///   - features: 自転車ポートの情報
    /// - Returns: MapLibreのソース
    func createStationSource(_ style: MLNStyle, features: [MLNPointFeature]) -> MLNSource {
      let source = MLNShapeSource(identifier: "bike-station-source", features: features)
      style.addSource(source)

      return source
    }

    /// 地図に表示する円のレイヤー設定をします
    /// - Parameter source: 地図に表示するソース
    /// - Returns: レイヤー情報
    func createStationCircleLayer(_ source: MLNSource) -> MLNCircleStyleLayer {

      // 台数によって円の色を変化させます
      let stops: [NSNumber: UIColor] = [
        0: .red,
        1: .yellow,
        2: .yellow,
        3: .green,
      ]

      let circleLayer = MLNCircleStyleLayer(identifier: "station-circle-layer", source: source)
      circleLayer.circleRadius = NSExpression(forConstantValue: 14)
      circleLayer.circleColor = NSExpression(
        format: "mgl_interpolate:withCurveType:parameters:stops:(bike_available, 'linear', nil, %@)",
        stops
      )
      return circleLayer
    }

    /// 地図に表示する残り台数のレイヤー設定をします
    /// - Parameter source: 地図に表示するソース
    /// - Returns: レイヤー情報
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

  
  /// 描画用のFeaturesを作成します
  /// - Parameter mapView: MapView
  /// - Returns: MLNPointFeature
  func createFeatures(_ mapView: MLNMapView) -> [MLNPointFeature] {
    return stationInformationProvider.stations.compactMap({ information in
      // 位置を取得
      let coordinate = CLLocationCoordinate2D(latitude: information.lat, longitude: information.lon)
      let center = mapView.centerCoordinate

      // 距離を計測
      let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
      let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

      let distance = location.distance(from: centerLocation)

      // 距離が5km以上の場合は表示しない
      if (distance > 5000) {
        return nil
      }

      let feature = MLNPointFeature()
      feature.coordinate = coordinate

      let status = stationStatusProvider.stations.first(where: {$0.station_id == information.station_id})


      guard let status = status else {
        return nil
      }

      feature.attributes = [
        "bike_available": status.num_bikes_available
      ]

      return feature
    })
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
