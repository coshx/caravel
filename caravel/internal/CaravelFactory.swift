/**
 **CaravelFactory**

 Manages the different Caravel instances and ensures they are all singletons
 */
internal class CaravelFactory {
    fileprivate static let defaultBusLock = NSObject()
    fileprivate static var defaultBus: Caravel?

    fileprivate static let creationLock = NSObject()
    // A lock per bus. Uses lock above when initializing
    fileprivate static var busLocks: [String: NSObject] = [:]
    fileprivate static var buses: [String: Caravel] = [:]

    fileprivate static func getLock(_ name: String) -> NSObject {
        if let o = busLocks[name] {
            return o
        } else {
            objc_sync_enter(creationLock)
            if let o = busLocks[name] {
                objc_sync_exit(creationLock)
                return o
            } else {
                let o = NSObject()
                busLocks[name] = o
                objc_sync_exit(creationLock)
                return o
            }
        }
    }

    internal static func getDefault() -> Caravel {
        let getExisting = { () -> Caravel? in
            if let b = defaultBus {
                return b
            } else {
                return nil
            }
        }

        if let bus = getExisting() {
            return bus
        } else {
            objc_sync_enter(defaultBusLock)
            if let bus = getExisting() {
                objc_sync_exit(defaultBusLock)
                return bus
            } else {
                self.defaultBus = Caravel(name: Caravel.DefaultBusName)
                objc_sync_exit(defaultBusLock)
                return self.defaultBus!
            }
        }
    }

    internal static func get(_ name: String) -> Caravel {
        if name == Caravel.DefaultBusName {
            return getDefault()
        } else {
            let getExisting = { () -> Caravel? in
                if let b = buses[name] {
                    return b
                } else {
                    return nil
                }
            }

            if let bus = getExisting() {
                return bus
            } else {
                objc_sync_enter(getLock(name))
                if let bus = getExisting() {
                    objc_sync_exit(getLock(name))
                    return bus
                } else {
                    let newBus = Caravel(name: name)
                    self.buses[name] = newBus
                    objc_sync_exit(getLock(name))
                    return newBus
                }
            }
        }
    }
}
