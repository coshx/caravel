/**
 **CaravelError**

 Potential erros that Caravel might throw
 */
public enum CaravelError: ErrorType {
    /**
     An EventBus' draft was used twice, which is forbidden
     */
    case DraftUsedTwice
    
    /**
     An unsupported type was provided when posting an event from iOS
     */
    case SerializationUnsupportedData
    
    /**
     User is trying to create a bus with a subscriber identical to the watched target
    */
    case SubscriberIsSameThanTarget
}