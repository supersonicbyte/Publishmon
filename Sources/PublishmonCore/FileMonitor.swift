import Foundation
import CoreServices

final class FileMonitor {
    typealias EventHandler = ((_ paths: [String]) -> Void)?
    
    private var isRunning: Bool = false
    let path: String
    let queue = DispatchQueue(label: "com.publishmon.FileMonitor")
    var stream: FSEventStreamRef?
    let eventHandler: EventHandler
    
    
    init(path: String, eventHandler: EventHandler) throws {
        self.path = path
        self.eventHandler = eventHandler
    }
    
    func start() {
        guard !isRunning else { return }
        
        let pathsToWatch = [path] as CFArray
        let latency: CFTimeInterval = 0
        let id = FSEventStreamEventId(kFSEventStreamEventIdSinceNow)
        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamEventFlagNone)
        
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        self.stream = FSEventStreamCreate(nil, eventCallback, &context, pathsToWatch, id, latency, flags)!
        
        FSEventStreamSetDispatchQueue(stream!, queue)
        
        FSEventStreamStart(stream!)
        
        isRunning = true
    }
    
    func stop() {
        guard let stream, isRunning  else { return }
        FSEventStreamStop(stream)
        isRunning = false
    }
        
    deinit {
        guard let stream else { return }
        FSEventStreamRelease(stream)
    }
}

fileprivate func eventCallback(
    stream: ConstFSEventStreamRef,
    info: UnsafeMutableRawPointer?,
    numEvents: Int,
    eventPaths: UnsafeMutableRawPointer,
    eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    eventIds: UnsafePointer<FSEventStreamEventId>
) -> Void {
    guard let info else { return }
    let monitor = Unmanaged<FileMonitor>.fromOpaque(info).takeUnretainedValue()
    guard let eventPaths = unsafeBitCast(eventPaths, to: CFArray.self) as? [String] else {
        print("❌ Error casting eventPaths to CFArray!")
        monitor.eventHandler?([])
        return
    }
    monitor.eventHandler?(eventPaths)
}

