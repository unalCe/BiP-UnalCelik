import UIKit

/// What the shell runs: something that owns a navigation stack and can put
/// its first screen on it. The shell keeps the coordinator alive for as long
/// as its flow is on screen.
@MainActor
protocol FlowCoordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func start()
}
