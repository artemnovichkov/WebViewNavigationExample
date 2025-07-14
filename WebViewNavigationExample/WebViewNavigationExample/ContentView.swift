//
//  Created by Artem Novichkov on 14.07.2025.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @State private var webPage = WebPage()
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            if webPage.isLoading {
                ProgressView("Loading...", value: webPage.estimatedProgress)
                    .padding(.horizontal)
            } else {
                WebView(webPage)
                    .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .onAppear {
            let navigationDecider = NavigationDecider()
            navigationDecider.urlToOpen = { url in
                if let url {
                    openURL(url)
                }
            }
            webPage = WebPage(navigationDecider: navigationDecider)
            let request = URLRequest(url: URL(string: "https://www.artemnovichkov.com")!)
            webPage.load(request)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                BackForwardMenu(
                    list: webPage.backForwardList.backList.reversed(),
                    label: .init(text: "Backward", systemImage: "chevron.backward")
                ) { item in
                    webPage.load(item)
                }
                BackForwardMenu(
                    list: webPage.backForwardList.forwardList,
                    label: .init(text: "Forward", systemImage: "chevron.forward")
                ) { item in
                    webPage.load(item)
                }
                Spacer()
                Button(action: {
                    webPage.reload()
                }, label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                })
                if let url = webPage.url {
                    ShareLink(item: url)
                }
            }
        }
    }
}

private struct BackForwardMenu: View {
    struct LabelConfiguration {
        let text: String
        let systemImage: String
    }

    let list: [WebPage.BackForwardList.Item]
    let label: LabelConfiguration
    let navigateToItem: (WebPage.BackForwardList.Item) -> Void

    var body: some View {
        Menu {
            ForEach(list) { item in
                Button(item.title ?? item.url.absoluteString) {
                    navigateToItem(item)
                }
            }
        } label: {
            Label(label.text, systemImage: label.systemImage)
        } primaryAction: {
            navigateToItem(list.first!)
        }
        .disabled(list.isEmpty)
    }
}

final class NavigationDecider: WebPage.NavigationDeciding {

    var urlToOpen: ((URL?) -> Void)?

    func decidePolicy(for action: WebPage.NavigationAction, preferences: inout WebPage.NavigationPreferences) async -> WKNavigationActionPolicy {
        let url = action.request.url
        if url?.host() == "www.artemnovichkov.com" {
            return .allow
        }
        urlToOpen?(url)
        return .cancel
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
