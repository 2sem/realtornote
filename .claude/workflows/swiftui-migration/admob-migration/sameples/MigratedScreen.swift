struct RecipientRuleListScreen: View {
    @EnvironmentObject private var adManager: SwiftUIAdManager
    @AppStorage("LastFullAdShown") var lastFullAdShown: Date = Date.distantPast

    var body: some View {
        ...
        Button(...) {
            presentFullAdThen {
                state = newState
            }
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