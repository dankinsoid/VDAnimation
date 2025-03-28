import Foundation

struct AnyCodingKey: CodingKey, LosslessStringConvertible, CustomStringConvertible {

    var stringValue: String
    var intValue: Int?
    var description: String { stringValue }
    
    init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init(intValue: Int) {
        stringValue = "\(intValue)"
        self.intValue = intValue
    }
    
    init(_ string: String) {
        self.init(stringValue: string)
    }
    
    init(_ int: Int) {
        self.init(intValue: int)
    }
}
