import XCTest
final class DriveTests: XCTestCase {
    func testDrive() throws {
        let dir = ProcessInfo.processInfo.environment["DRV_DIR"] ?? "/private/tmp/photoswipe-sim-driver"
        let cmdURL = URL(fileURLWithPath: dir + "/cmd"), doneURL = URL(fileURLWithPath: dir + "/done")
        let app = XCUIApplication(bundleIdentifier: "com.warrenlimzf.photoswipe")
        app.activate()
        func pt(_ x: Double, _ y: Double) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(CGVector(dx: x, dy: y))
        }
        var seq = -1
        while true {
            guard let s = try? String(contentsOf: cmdURL, encoding: .utf8) else { usleep(100_000); continue }
            let lines = s.split(separator: "\n").map(String.init)
            guard let first = lines.first, let n = Int(first), n != seq else { usleep(100_000); continue }
            seq = n
            var out = "ok"
            for line in lines.dropFirst() {
                let p = line.split(separator: " ").map(String.init)
                guard let c = p.first else { continue }
                let d = p.dropFirst().compactMap { Double($0) }
                switch c {
                case "quit": try? "\(n) bye".write(to: doneURL, atomically: true, encoding: .utf8); return
                case "launch": app.activate()
                case "tap": pt(d[0], d[1]).tap()
                case "long": pt(d[0], d[1]).press(forDuration: d[2])
                case "drag": // x1 y1 x2 y2 pressDur velocity hold
                    pt(d[0], d[1]).press(forDuration: d.count > 4 ? d[4] : 0.05, thenDragTo: pt(d[2], d[3]),
                        withVelocity: XCUIGestureVelocity(rawValue: d.count > 5 ? d[5] : 1000),
                        thenHoldForDuration: d.count > 6 ? d[6] : 0)
                case "swipeup": app.swipeUp()
                case "swipedown": app.swipeDown()
                case "sleep": usleep(UInt32(d[0] * 1_000_000))
                case "tree": out = app.debugDescription
                default: out = "unknown \(c)"
                }
            }
            try? "\(n) \(out)".write(to: doneURL, atomically: true, encoding: .utf8)
        }
    }
}
