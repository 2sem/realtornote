extension SwiftUIAdManager {
    enum GADUnitName: String {
        // GADUnitName from AppDelegate
    }
    
#if DEBUG
    var testUnits: [GADUnitName] {
        [
            //all cases
        ]
    }
#else
    var testUnits: [GADUnitName] { [] }
#endif
    
}