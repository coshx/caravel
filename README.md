# Caravel

[![CocoaPods](https://img.shields.io/cocoapods/v/Caravel.svg?style=flat-square)](https://cocoapods.org/pods/Caravel)

**An event bus for sending messages between UIWebView and embedded JS. Made with pure Swift.**

## Features

* Easy event bus system
* Supports `Bool`, `Int`, `Float`, `Double`, `String`, `NSArray` and `NSDictionary` data from iOS
* Supports integer, float, double and string data from JavaScript
* Multiple bus support
* `When Ready` event: do not miss any event from your lovely Swift controller!

## Installation

Install Caravel using CocoaPods:

```ruby
pod 'Caravel'
```

Otherwise, you can install it as a submodule of your project.

Once done, you should find a `caravel.min.js` file in either the Pod or the submodule. Add this file to your project. Then, in each HTML page you have, load it before running your main script:

```html
<script type="text/javascript" src="caravel.min.js"></script>
```

## Get started

Caravel allows developers to communicate between their `UIWebView` and the embedded JS. You can send any kind of message between those two folks.

Have a glance at this super simple sample. Let's start with the iOS part:

```swift
import Caravel

class MyController: UIViewController {
    @IBOutlet weak var webView: UIWebView!
    
    func viewDidLoad() {
        super.viewDidLoad()
        
        Caravel.getDefault().whenReady() { bus in
            bus.post("AnEvent", anArray: [1, 2, 3])
        }
        
        // Load web view content below
    }
}
```

And now, in your JS:

```javascript
Caravel.getDefault().register("AnEvent", function(name, data) {
    alert('I received this array: ' + data);
});
```

And voilà!

## API

### Swift - Caravel class

```swift
/**
 * Returns the default bus
 */
static func getDefault(webView: UIWebView) -> Caravel
```

```swift
/**
 * Returns custom bus
 */
static func get(name: String, webView: UIWebView) -> Caravel
```

```swift
/**
 * Returns the current bus when its JS counterpart is ready
 */
func whenReady(callback: (Caravel) -> Void)
```

```swift
/**
 * Posts event without any argument
 */
func post(eventName: String)
```

```swift
/**
 * Posts event with extra data
 */
func post(eventName: String, data: AnyObject)
```

**NB:** Caravel is smart enough for serializing nested objects (eg. an array wrapped into a dictionary). However, this serialization only works if nested types are supported ones.

```swift
/**
 * Subscribes to provided event. Callback is run with the event's name and extra data
 */
func register(eventName: String, callback: (String, AnyObject?) -> Void)
```

### JS - Caravel class

```js
/**
 * Returns default bus
 */
static function getDefault()
```

```js
/**
 * Returns custom bus
 */
static function get(name)
```

```js
/**
 * Subscribes to provided event. Callback is called with event name first, then extra data if any
 */
static function register(name, callback)
```

```js
/**
 * Posts event. Data are optional
 */
static function post(name, data)
```

## Troubleshooting

### I have my custom UIWebViewDelegate. What should I do?

Caravel saves the current delegate, if any, before setting its own. So, if you would like to use your custom one, you have to set it before any call to Caravel.

### Reserved names

`CaravelInit` is an internal event, sent by the JS part for triggering the `whenReady` method.

Also, the default bus is named `default`. If you use that name for a custom bus, Caravel will automatically use the default one.

