import SwiftUI

struct OnboardingView: View {
    @ObservedObject var prefs = PreferencesManager.shared
    @ObservedObject var appState = AppState.shared
    
    var onComplete: () -> Void
    var onPreview: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Hero Section
            VStack(spacing: 16) {
                Image(systemName: "macbook.and.iphone")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 64)
                    .foregroundColor(.accentColor)
                    .padding(.top, 40)
                    .shadow(color: .accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Text("Welcome to LidMotion")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                
                Text("Transform your Mac's lid closure into a stunning visual experience, inspired by iOS.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 40)
            
            // Feature List
            VStack(alignment: .leading, spacing: 24) {
                FeatureRow(
                    icon: "eye",
                    title: "3D Hologram",
                    description: "Your desktop image folds into real space as you close the screen."
                )
                
                FeatureRow(
                    icon: "sparkles",
                    title: "Preview Animation",
                    description: "Click below to see the effect in action without closing your Mac.",
                    action: "Try now",
                    onAction: onPreview
                )
                
                FeatureRow(
                    icon: "lock.shield",
                    title: "Permissions Required",
                    description: "LidMotion needs 'Screen Recording' and 'Accessibility' permissions to animate the lid and read your desktop pixels. Data NEVER leaves your Mac.",
                    action: appState.hasScreenRecordingPermission ? "✓ Authorized" : "Open Settings...",
                    onAction: appState.hasScreenRecordingPermission ? nil : { appState.requestPermissions() },
                    isSuccess: appState.hasScreenRecordingPermission
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                Button("Start using the App") {
                    prefs.hasCompletedOnboarding = true
                    onComplete()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
                .disabled(!appState.hasScreenRecordingPermission)
            }
            .padding(20)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.3))
        }
        .frame(width: 480, height: 560)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
    }
}

struct FeatureRow: View {
    var icon: String
    var title: String
    var description: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil
    var isSuccess: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(isSuccess ? .green : .accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let action = action, let onAction = onAction {
                    Button(action) {
                        onAction()
                    }
                    .controlSize(.small)
                    .padding(.top, 4)
                } else if let action = action {
                    Text(action)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.top, 4)
                }
            }
        }
    }
}
