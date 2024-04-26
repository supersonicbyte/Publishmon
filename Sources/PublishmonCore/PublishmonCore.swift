import Foundation
import ShellOut

public final class Publishmon {
    private let arguments: [String]
    private lazy var portNumber: Int = {
        return extractPortNumber(from: arguments)
    }()
    private var monitor: FileMonitor?
    private let publishQueue = DispatchQueue(label: "Publishmon.PublishQueue")
    private var currentDirectoryPath: String {
        return FileManager.default.currentDirectoryPath
    }
    private var serverProcess = Process()
    
    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }
    
    public func run() throws {
        print("🔥 Firing up publishmon")
        
        runPublish()
        
        self.monitor = try FileMonitor(path: currentDirectoryPath, eventHandler: { [weak self] paths in
            guard let self else { return }
             
            let normalizedPaths = paths.compactMap { $0.split(separator: self.currentDirectoryPath).last }.map { String($0) }
                        
            #if DEBUG
            print("\(Date.now) File paths that changed: \n \(normalizedPaths)")
            #endif
            
            // If path is Output or is  hidden directory ( .build, .swiftpm, etc.)
            // we ignore the file change so we don't run into a infinite loop.
            // Also we skip if the paths array is empty.
            if normalizedPaths.contains(where: { self.shouldIngore(path: $0) }) || normalizedPaths.isEmpty {
                return
            }
            
            // Re-run publish
            print("🔁 Restarting. File changes detected.")
            if serverProcess.isRunning {
                serverProcess.terminate()
            }
            self.serverProcess = Process()
            self.runPublish()
        })
        self.monitor?.start()
        
        _ = readLine()
        
        if serverProcess.isRunning {
            serverProcess.terminate()
        }
    }
    
    private func runPublish() {
        // Generate new files with publish
        do {
            var generateProcess = Process()
            try shellOut(
                to: ["publish generate"],
                process: generateProcess,
                outputHandle: FileHandle.standardOutput,
                errorHandle: FileHandle.standardOutput
            )
            generateProcess.terminate()
        } catch {
            print("\n❌ Failed to run publish generate:\n\(error.localizedDescription)\n")
        }
     
        publishQueue.async { [weak self] in
            guard let self else { return }
            do {
                _ = try shellOut(
                    to: "python3 -m http.server 8000",
                    at: FileManager.default.currentDirectoryPath.appending("/Output"),
                    process: self.serverProcess,
                    outputHandle: FileHandle.standardOutput,
                    errorHandle: FileHandle.standardOutput
                )
            } catch let error as ShellOutError {
                // termination status 15 is SIGTERM, meaning the process was terminated
                guard error.terminationStatus != 15 else {
                    return
                }
                outputServerErrorMessage(error.message)
            } catch {
                print(error)
                outputServerErrorMessage(error.localizedDescription)
            }
            
        }
    }
    
    private func shouldIngore(path: String) -> Bool {
        return path.hasPrefix("/Output") || path.hasPrefix("/.")
    }
    
    private func extractPortNumber(from arguments: [String]) -> Int {
        if arguments.count > 3 {
            switch arguments[2] {
            case "-p", "--port":
                guard let portNumber = Int(arguments[3]) else {
                    break
                }
                return portNumber
            default:
                return 8000 // default portNumber
            }
        }
        return 8000 // default portNumber
    }
    
    private func outputServerErrorMessage(_ message: String) {
        var message = message
        
        if message.hasPrefix("Traceback"),
           message.contains("Address already in use") {
            message = """
                A localhost server is already running on port number \(self.portNumber).
                - Perhaps another 'publish run' session is running?
                - Publish uses Python's simple HTTP server, so to find any
                  running processes, you can use either Activity Monitor
                  or the 'ps' command and search for 'python'. You can then
                  terminate any previous process in order to start a new one.
                """
        }
        
        fputs("\n❌ Failed to start local web server:\n\(message)\n", stderr)
    }
}
