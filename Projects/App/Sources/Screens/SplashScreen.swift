import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            // Background color
            Color(red: 0.204, green: 0.396, blue: 0.694)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Logo - centered, 60% width
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                
                Spacer()
                
                // Icons8 attribution section
                HStack(spacing: 8) {
                    Spacer()
                    
                    Image("Icons8")
                        .resizable()
                        .frame(width: 44, height: 44)
                    
                    Text("Icons8")
                        .font(.system(size: 17))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                        .frame(width: 59, height: 21)
                }
                .padding(.trailing, 4)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.882, green: 0.961, blue: 0.996))
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SplashScreen()
}
