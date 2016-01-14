/**
 **CaravelError**

 Potential erros that Caravel maight throw
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
}