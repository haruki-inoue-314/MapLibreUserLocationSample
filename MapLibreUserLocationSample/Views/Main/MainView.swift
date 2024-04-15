import SwiftUI

struct MainView: View {
  var body: some View {
    ZStack {
      MapView()
        .ignoresSafeArea()
    }
  }
}

#Preview {
  MainView()
}
