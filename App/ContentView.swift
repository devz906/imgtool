import SwiftUI
import UIKit

struct ContentView: View {
    @State private var isJITInitialized = false
    @State private var isBox64Initialized = false
    @State private var pageSize: Int = 0
    @State private var systemPageSize: String = ""
    @State private var statusMessage = "Ready to initialize JIT environment"
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Section
                VStack(spacing: 15) {
                    Text("IMGTool - Box64 Environment")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(statusMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // JIT Status Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: isJITInitialized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isJITInitialized ? .green : .red)
                        Text("JIT Environment")
                            .font(.headline)
                    }
                    
                    Text(isJITInitialized ? "Initialized and ready" : "Not initialized")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Box64 Status Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: isBox64Initialized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isBox64Initialized ? .green : .red)
                        Text("Box64 Environment")
                            .font(.headline)
                    }
                    
                    Text(isBox64Initialized ? "Initialized and ready" : "Not initialized")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Page Size Info
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "memorychip")
                            .foregroundColor(.blue)
                        Text("System Page Size")
                            .font(.headline)
                    }
                    
                    Text(pageSize > 0 ? "\(pageSize) bytes" : "Unknown")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if pageSize == 16384 {
                        Text("✅ Optimal 16KB page size detected")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else if pageSize == 4096 {
                        Text("⚠️ 4KB page size - supported but less optimal")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Control Buttons
                VStack(spacing: 15) {
                    Button(action: initializeJIT) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Initialize JIT Environment")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(isJITInitialized)
                    
                    Button(action: initializeBox64) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                            Text("Initialize Box64")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isJITInitialized ? Color.green : Color.gray)
                        .cornerRadius(10)
                    }
                    .disabled(!isJITInitialized || isBox64Initialized)
                    
                    Button(action: resetEnvironment) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Reset Environment")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("IMGTool")
            .alert("Status", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func initializeJIT() {
        statusMessage = "Initializing JIT environment..."
        
        DispatchQueue.global(qos: .userInitiated).async(execute: DispatchWorkItem {
            let jitManager = JITManager.sharedManager()
            var error: NSError?
            let success = jitManager.enableJITWithError(&error)
            
            DispatchQueue.main.async(execute: DispatchWorkItem {
                if success {
                    self.isJITInitialized = true
                    self.statusMessage = "JIT environment initialized successfully"
                    self.alertMessage = "JIT environment is ready! Memory allocation and write protection are enabled."
                    self.showingAlert = true
                    
                    // Check page size after JIT initialization
                    self.checkPageSize()
                } else {
                    self.statusMessage = "JIT initialization failed"
                    self.alertMessage = "Failed to initialize JIT environment. Please ensure proper entitlements are set."
                    self.showingAlert = true
                }
            })
        })
    }
    
    private func initializeBox64() {
        statusMessage = "Initializing Box64 environment..."
        
        DispatchQueue.global(qos: .userInitiated).async(execute: DispatchWorkItem {
            let jitManager = JITManager.sharedManager()
            let use16KPages = jitManager.supports16KPages()
            var error: NSError?
            let success = jitManager.initializeBox64With16KPages(use16KPages, error: &error)
            
            DispatchQueue.main.async(execute: DispatchWorkItem {
                if success {
                    self.isBox64Initialized = true
                    self.statusMessage = "Box64 environment initialized successfully"
                    self.alertMessage = "Box64 is ready! \(use16KPages ? "16KB pages" : "4KB pages") optimization enabled."
                    self.showingAlert = true
                } else {
                    self.statusMessage = "Box64 initialization failed"
                    self.alertMessage = "Failed to initialize Box64 environment."
                    self.showingAlert = true
                }
            })
        })
    }
    
    private func checkPageSize() {
        DispatchQueue.global(qos: .userInitiated).async(execute: DispatchWorkItem {
            let jitManager = JITManager.sharedManager()
            let supports16K = jitManager.supports16KPages()
            
            DispatchQueue.main.async(execute: DispatchWorkItem {
                self.systemPageSize = supports16K ? "16KB" : "4KB"
                self.statusMessage = "Page size detected: \(self.systemPageSize)"
            })
        })
    }
    
    private func resetEnvironment() {
        isJITInitialized = false
        isBox64Initialized = false
        pageSize = 0
        statusMessage = "Environment reset - ready to initialize"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
