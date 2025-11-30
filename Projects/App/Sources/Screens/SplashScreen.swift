import SwiftUI

struct SplashScreen: View {
    @StateObject private var migrationManager = DataMigrationManager()
    
    var body: some View {
        ZStack {
            // Background color
            Color(red: 0.204, green: 0.396, blue: 0.694)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo - centered, 60% width
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.6)
                
                // Migration status
                switch migrationManager.migrationStatus {
                case .checking:
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text(migrationManager.currentStep)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                case .migrating:
                    VStack(spacing: 16) {
                        ProgressView(value: migrationManager.migrationProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .frame(width: 200)
                        
                        Text(migrationManager.currentStep)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                case .completed:
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        
                        Text(migrationManager.currentStep)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                case .failed(let error):
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        
                        Text("마이그레이션 실패")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Text(error.localizedDescription)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                case .idle:
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("앱을 초기화하는 중...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                
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
        .onAppear {
            startMigrationProcess()
        }
    }
    
    private func startMigrationProcess() {
        Task {
            _ = await migrationManager.checkAndMigrateIfNeeded()
            
            // TODO: Navigate to main app after migration completes
        }
    }
}

#Preview {
    SplashScreen()
}
