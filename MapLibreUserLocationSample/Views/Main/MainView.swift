import SwiftUI

struct MainView: View {

  @State var isShownErrorAlert = false
  @State var alertMessage = ""
  @State private var currentTask: Task<(), Never>?
  @StateObject var stationInformationProvider: GBFSStationInformationProvider = GBFSStationInformationProvider()
  @StateObject var stationStatusProvider: GBFSStationStatusProvider = GBFSStationStatusProvider()

  var body: some View {
    ZStack {
      MapView(
        isShownErrorAlert: $isShownErrorAlert,
        alertMessage: $alertMessage,
        stationInformationProvider: stationInformationProvider,
        stationStatusProvider: stationStatusProvider
      )
      .ignoresSafeArea()

//      Button {
//        currentTask?.cancel()
//        currentTask = Task {
//          do {
//            try await stationStatusProvider.fetchStationStatus()
//          } catch {
//            isShownErrorAlert = true
//            alertMessage = "データの取得に失敗しました"
//          }
//        }
//
//      } label: {
//        Text("更新")
//      }
    }

    // アラート
    .alert("Error", isPresented: $isShownErrorAlert) {
      // action
    } message: {
      Text(alertMessage)
    }

    .onDisappear {
      currentTask?.cancel()
    }
  }
}

#Preview {
  MainView()
}
