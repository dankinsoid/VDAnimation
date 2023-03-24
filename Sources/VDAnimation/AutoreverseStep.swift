import Foundation

public enum AutoreverseStep: Equatable {
    
    case forward, back
    
    public var inverted: AutoreverseStep {
        switch self {
        case .forward:  return .back
        case .back:     return .forward
        }
    }
}
