import SwiftUI

struct MainView: View {

  @State var isShownErrorAlert = false
  @State private var currentTask: Task<(), Never>?
  @StateObject var stationInformationProvider: GBFSStationInformationProvider = GBFSStationInformationProvider()
  @StateObject var stationStatusProvider: GBFSStationStatusProvider = GBFSStationStatusProvider()

  var body: some View {
    ZStack {
      MapView(
        stationInformationProvider: stationInformationProvider,
        stationStatusProvider: stationStatusProvider
      )
      .ignoresSafeArea()

      VStack {
        Spacer()
        Button {
          currentTask?.cancel()
          currentTask = Task {
            do {
              try await stationStatusProvider.fetchStationStatus()
            } catch {
              isShownErrorAlert = true
            }
          }

        } label: {
          Text("更新")
            .foregroundStyle(Color.white)
            .bold()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.blue)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 4)
      }
      .padding()

    }

    // アラート
    .alert("Error", isPresented: $isShownErrorAlert) {
      // action
    } message: {
      Text("データの取得に失敗しました")
    }

    //　最初のデータ取得処理
    .task {
      do {
        try await stationInformationProvider.fetchStationInformation()
        print("end information fetch")
        try await stationStatusProvider.fetchStationStatus()
        print("end status fetch")
      } catch {
        isShownErrorAlert = true
      }
    }

    // 画面を閉じたときの処理
    .onDisappear {
      currentTask?.cancel()
    }
  }
}

#Preview {
  MainView()
}
