/// A minimal interface with two implementations, so a test can tell which
/// one the engine handed back.
protocol GreeterInterface: Sendable { func greet() -> String }
struct EnglishGreeter: GreeterInterface { func greet() -> String { "hello" } }
struct TurkishGreeter: GreeterInterface { func greet() -> String { "merhaba" } }
