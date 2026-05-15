//
//  SNAP - https://github.com/simonnickel/snap
//  Created by Simon Nickel
//

internal extension Dependencies.Container {
    
    /// Wraps `PartialKeyPath<Dependencies>` to provide a checked `Sendable` conformance.
    ///
    /// `PartialKeyPath` inherits `@unchecked Sendable` from `AnyKeyPath` via class inheritance,
    /// but the compiler does not propagate that through conditional conformances (e.g. `Dictionary`)
    /// or `@Sendable` closure captures.
    struct Key: Hashable, @unchecked Sendable {
        
        let keyPath: PartialKeyPath<Dependencies>
        
        init(_ keyPath: PartialKeyPath<Dependencies>) {
            self.keyPath = keyPath
        }
        
    }
    
}
