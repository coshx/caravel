public protocol ICaravelSerializable {
    typealias T
    
    func fromJSON(input: String) -> T
    
    func toJSON(t: T) -> String
}