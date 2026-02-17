import Foundation
import UIKit

class WinlatorEngine {
    static let shared = WinlatorEngine()
    
    private var process: Process?
    private var isRunning = false
    private let winePrefix: String
    
    private init() {
        // Set WINEPREFIX to Documents directory
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        self.winePrefix = "\(documentsPath)/wineprefix"
        
        // Create wineprefix directory if it doesn't exist
        setupWinePrefix()
    }
    
    private func setupWinePrefix() {
        do {
            try FileManager.default.createDirectory(atPath: winePrefix, withIntermediateDirectories: true)
            
            // Create basic Wine directory structure
            let wineDirs = [
                "drive_c/windows",
                "drive_c/Program Files", 
                "drive_c/Program Files (x86)",
                "drive_c/Users",
                "drive_c/Windows/System32"
            ]
            
            for dir in wineDirs {
                let fullPath = "\(winePrefix)/\(dir)"
                try FileManager.default.createDirectory(atPath: fullPath, withIntermediateDirectories: true)
            }
            
            print("✅ Wine prefix setup completed at: \(winePrefix)")
            
        } catch {
            print("❌ Failed to setup wine prefix: \(error)")
        }
    }
    
    func startEngine() -> Bool {
        guard !isRunning else {
            print("⚠️ Engine is already running")
            return true
        }
        
        // Get path to embedded binary
        guard let binaryPath = Bundle.main.path(forResource: "winkor_engine", ofType: nil) else {
            print("❌ winkor_engine binary not found in bundle!")
            return false
        }
        
        print("🚀 Starting Winkor Engine from: \(binaryPath)")
        
        // Make binary executable
        do {
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binaryPath)
        } catch {
            print("⚠️ Could not set executable permissions: \(error)")
        }
        
        process = Process()
        process?.executableURL = URL(fileURLWithPath: binaryPath)
        
        // Set up environment
        var env = ProcessInfo.processInfo.environment
        env["WINEPREFIX"] = winePrefix
        env["WINEDEBUG"] = "+all"
        env["WINEDLLOVERRIDES"] = "winemenubuilder.exe=d"
        
        process?.environment = env
        
        // Set up pipes for output
        let pipe = Pipe()
        process?.standardOutput = pipe
        process?.standardError = pipe
        
        // Set up notification for process completion
        process?.terminationHandler = { [weak self] process in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.process = nil
                print("📴 Winkor Engine stopped with exit code: \(process.terminationCode)")
            }
        }
        
        do {
            try process?.run()
            isRunning = true
            print("✅ Winkor Engine started successfully!")
            
            // Start monitoring output
            monitorOutput(pipe: pipe)
            
            return true
        } catch {
            print("❌ Failed to start Winkor Engine: \(error)")
            return false
        }
    }
    
    private func monitorOutput(pipe: Pipe) {
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            if !output.isEmpty {
                print("📝 Engine output: \(output)")
            }
        }
        
        // Continue monitoring
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            
            if let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    print("📝 Engine: \(output)")
                }
            }
        }
    }
    
    func stopEngine() {
        guard let process = process, isRunning else {
            print("⚠️ Engine is not running")
            return
        }
        
        print("🛑 Stopping Winkor Engine...")
        process.terminate()
        
        // Force kill if it doesn't terminate gracefully
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            if let process = self?.process, process.isRunning {
                print("⚡ Force killing Winkor Engine...")
                process.kill()
            }
        }
    }
    
    func isEngineRunning() -> Bool {
        return isRunning && (process?.isRunning ?? false)
    }
    
    func getWinePrefix() -> String {
        return winePrefix
    }
    
    func executeWindowsProgram(_ programPath: String, arguments: [String] = []) -> Bool {
        guard !isRunning else {
            print("⚠️ Cannot execute program while engine is running")
            return false
        }
        
        // Get path to embedded binary
        guard let binaryPath = Bundle.main.path(forResource: "winkor_engine", ofType: nil) else {
            print("❌ winkor_engine binary not found in bundle!")
            return false
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        
        // Set up environment
        var env = ProcessInfo.processInfo.environment
        env["WINEPREFIX"] = winePrefix
        env["WINEDEBUG"] = "+all"
        
        process.environment = env
        
        // Set up arguments
        var args = [programPath]
        args.append(contentsOf: arguments)
        process.arguments = args
        
        // Set up pipes for output
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            print("✅ Started Windows program: \(programPath)")
            
            // Wait for completion and get output
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print("📝 Program output: \(output)")
            }
            
            return process.terminationCode == 0
        } catch {
            print("❌ Failed to execute Windows program: \(error)")
            return false
        }
    }
}
