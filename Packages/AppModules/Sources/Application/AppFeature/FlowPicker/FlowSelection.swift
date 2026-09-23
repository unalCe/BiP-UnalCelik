import CommonKit
import Foundation

public enum ArchitectureStyle: String, CaseIterable, Sendable {
    case mvvm, viper

    public var title: String {
        switch self {
        case .mvvm: return "MVVM-C"
        case .viper: return "VIPER"
        }
    }
}

public enum UIFramework: String, CaseIterable, Sendable {
    case uiKit, swiftUI

    public var title: String {
        switch self {
        case .uiKit: return "UIKit"
        case .swiftUI: return "SwiftUI"
        }
    }
}

public enum FlowStyle: String, CaseIterable, Sendable {
    case mvvmUIKit, mvvmSwiftUI, viperUIKit

    public var title: String {
        switch self {
        case .mvvmUIKit: return "MVVM-C · UIKit"
        case .mvvmSwiftUI: return "MVVM-C · SwiftUI"
        case .viperUIKit: return "VIPER · UIKit"
        }
    }
}

public struct FlowSelection: Equatable, Sendable {
    public private(set) var architecture: ArchitectureStyle
    public private(set) var uiFramework: UIFramework

    public init(architecture: ArchitectureStyle = .mvvm, uiFramework: UIFramework = .uiKit) {
        self.architecture = architecture
        self.uiFramework = (architecture == .viper) ? .uiKit : uiFramework
    }

    public init(style: FlowStyle) {
        switch style {
        case .mvvmUIKit: self.init(architecture: .mvvm, uiFramework: .uiKit)
        case .mvvmSwiftUI: self.init(architecture: .mvvm, uiFramework: .swiftUI)
        case .viperUIKit: self.init(architecture: .viper, uiFramework: .uiKit)
        }
    }

    public var isUIFrameworkSelectable: Bool { architecture == .mvvm }

    public var lockReason: String? {
        isUIFrameworkSelectable
            ? nil
            : AppStrings.FlowPicker.viperLockReason
    }

    public mutating func select(_ architecture: ArchitectureStyle) {
        self.architecture = architecture
        if architecture == .viper { uiFramework = .uiKit }
    }

    public mutating func select(_ uiFramework: UIFramework) {
        guard isUIFrameworkSelectable else { return }
        self.uiFramework = uiFramework
    }

    public var style: FlowStyle {
        switch (architecture, uiFramework) {
        case (.mvvm, .uiKit): return .mvvmUIKit
        case (.mvvm, .swiftUI): return .mvvmSwiftUI
        case (.viper, _): return .viperUIKit
        }
    }
}
