/**
 **CaravelError**

 Potential erros that Caravel might throw
 */
public enum CaravelError: Error {
    /**
     An EventBus' draft was used twice, which is forbidden
     */
    case draftUsedTwice
    
    /**
     An unsupported type was provided when posting an event from iOS
     */
    case serializationUnsupportedData
    
    /**
     User is trying to create a bus with a subscriber identical to the watched target
    */
    case subscriberIsSameThanTarget
}
