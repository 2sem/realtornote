import SwiftUI
import FirebaseAnalytics

/// External links bar positioned above the tab bar
struct ExternalLinksBar: View {
    @EnvironmentObject private var adManager: SwiftUIAdManager
    @AppStorage(LSDefaults.Keys.LaunchCount) private var launchCount: Int = 0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var safariURL: SafariURL?
    
    // Adaptive spacing based on device size class
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .compact ? 16 : 20
    }
    
    private var buttonSpacing: CGFloat {
        horizontalSizeClass == .compact ? 4 : 8
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: buttonSpacing) {
                // Q-Net 공인중개사
                LinkButton(
                    title: "Q-Net\n공인중개사",
                    backgroundColor: Color(red: 0.259, green: 0.647, blue: 0.961),
                    url: URL(string: "http://www.q-net.or.kr/man001.do?gSite=L&gId=08")!,
                    event: .openQNet,
                    action: {
                        presentFullAdThen {
                            safariURL = .init(url: URL(string: "http://www.q-net.or.kr/man001.do?gSite=L&gId=08")!)
                        }
                    }
                )
                
                // 공인중개사 요약집
                LinkButton(
                    title: "공인중개사\n요약집",
                    backgroundColor: Color(red: 0.098, green: 0.463, blue: 0.824),
                    url: URL(string: "http://andy1002.cafe24.com/gnu_house")!,
                    event: .openQuizWin,
                    action: {
                        presentFullAdThen {
                            safariURL = .init(url: URL(string: "http://andy1002.cafe24.com/gnu_house")!)
                        }
                    }
                )
                
                // QuizWin 기출문제
                LinkButton(
                    title: "QuizWin\n기출문제",
                    backgroundColor: Color(red: 1.0, green: 0.627, blue: 0.0),
                    url: URL(string: "http://landquiz.com/bbs/gichul.php")!,
                    event: .openQuizWin,
                    action: {
                        presentFullAdThen {
                            safariURL = .init(url: URL(string: "http://landquiz.com/bbs/gichul.php")!)
                        }
                    }
                )
                
                // 공인중개사 시행령
                LinkButton(
                    title: "공인중개사\n시행령",
                    backgroundColor: Color(red: 1.0, green: 0.757, blue: 0.027),
                    url: URL(string: "https://www.law.go.kr/%EB%B2%95%EB%A0%B9/%EA%B3%B5%EC%9D%B8%EC%A4%91%EA%B0%9C%EC%82%AC%EB%B2%95%EC%8B%9C%ED%96%89%EB%A0%B9")!,
                    event: .openRealtorRaw,
                    action: {
                        presentFullAdThen {
                            safariURL = .init(url: URL(string: "https://www.law.go.kr/%EB%B2%95%EB%A0%B9/%EA%B3%B5%EC%9D%B8%EC%A4%91%EA%B0%9C%EC%82%AC%EB%B2%95%EC%8B%9C%ED%96%89%EB%A0%B9")!)
                        }
                    }
                )
            }
            .frame(height: 44)
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(
            Color(red: 0.506, green: 0.831, blue: 0.980)
                .ignoresSafeArea(edges: .bottom)
        )
        .sheet(item: $safariURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }
    
    private func presentFullAdThen(_ action: @escaping () -> Void) {
        guard launchCount > 1 else {
            action()
            return
        }
        
        Task {
            await adManager.requestAppTrackingIfNeed()
            await adManager.show(unit: .full)
            action()
        }
    }
}

struct LinkButton: View {
    let title: String
    let backgroundColor: Color
    let url: URL
    let event: Analytics.LeesamEvent
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            Analytics.logLeesamEvent(event, parameters: [:])
            action?()
        } label: {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundColor)
                .cornerRadius(4)
        }
    }
}

#Preview {
    ExternalLinksBar()
        .background(Color.gray.opacity(0.2))
}
