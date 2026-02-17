import SwiftUI
import UIKit

struct ContentView: View {
    @State private var isEngineRunning = false
    @State private var statusMessage = "Ready to start Winkor Engine"
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @StateObject private var engine = WinlatorEngine.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Section
                VStack(spacing: 15) {
                    Text("IMGTool - Winkor Engine")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(statusMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Winkor Engine Status Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: isEngineRunning ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isEngineRunning ? .green : .red)
                        Text("Winkor Engine")
                            .font(.headline)
                    }
                    
                    Text(isEngineRunning ? "Running and ready" : "Stopped")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Wine Prefix Info
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.blue)
                        Text("Wine Prefix")
                            .font(.headline)
                    }
                    
                    Text(engine.getWinePrefix())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
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
                    Button(action: startEngine) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text(isEngineRunning ? "Engine Running" : "Start Winkor Engine")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isEngineRunning ? Color.green : Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(isEngineRunning)
                    
                    Button(action: stopEngine) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop Engine")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .disabled(!isEngineRunning)
                    
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
    
    private func startEngine() {
        statusMessage = "Starting Winkor Engine..."
        
        DispatchQueue.global(qos: .userInitiated).async(execute: DispatchWorkItem {
            let success = self.engine.startEngine()
            
            DispatchQueue.main.async(execute: DispatchWorkItem {
                if success {
                    self.isEngineRunning = true
                    self.statusMessage = "Winkor Engine started successfully"
                    self.alertMessage = "Winkor Engine is running! Wine prefix configured and ready."
                    self.showingAlert = true
                } else {
                    self.statusMessage = "Failed to start Winkor Engine"
                    self.alertMessage = "Could not start the Winkor Engine. Check binary permissions and storage."
                    self.showingAlert = true
                }
            })
        })
    }
    
    private func stopEngine() {
        statusMessage = "Stopping Winkor Engine..."
        
        DispatchQueue.global(qos: .userInitiated).async(execute: DispatchWorkItem {
            self.engine.stopEngine()
            
            DispatchQueue.main.async(execute: DispatchWorkItem {
                self.isEngineRunning = false
                self.statusMessage = "Winkor Engine stopped"
                self.alertMessage = "Winkor Engine has been stopped."
                self.showingAlert = true
            })
        })
    }
    
    private func resetEnvironment() {
        isEngineRunning = false
        statusMessage = "Environment reset - ready to start engine"
        alertMessage = "Environment has been reset. You can start the engine again."
        showingAlert = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
