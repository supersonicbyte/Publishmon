import PublishmonCore
import Foundation

let publishmon = Publishmon()

do {
    try publishmon.run()
} catch {
    print("❌ Whoops! An error occurred: \(error.localizedDescription)")
}
