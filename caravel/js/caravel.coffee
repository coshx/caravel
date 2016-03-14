# @class Caravel
# @brief Caravel JS bus
class Caravel
  @default = null
  @buses = []

  constructor: (name)  ->
    @name = name
    @subscribers = []
    @isUsingWKWebView = window.webkit? &&
                        window.webkit.messageHandlers? &&
                        window.webkit.messageHandlers.caravel?

  # Internal method for posting
  _post: (eventName, data) ->
    action = null

    if @isUsingWKWebView
      body =
        busName: @name
        eventName: eventName
        eventData: data
      action = () => window.webkit.messageHandlers.caravel.postMessage(body)
    else
      # shouldLoadRequest is only triggered when a new content is required
      # Ajax requests are useless
      action = () =>
        iframe = document.createElement 'iframe'
        src = "caravel://host.com?busName=#{encodeURIComponent(@name)}&eventName=#{encodeURIComponent(eventName)}"
        if data?
          if data instanceof Array or data instanceof Object
            src += "&eventData=#{encodeURIComponent(JSON.stringify(data))}"
          else
            src += "&eventData=#{encodeURIComponent(data)}"
        iframe.setAttribute 'src', src
        document.documentElement.appendChild iframe
        iframe.parentNode.removeChild iframe

    setTimeout(action, 0)

  getName: () ->
    @name

  post: (name, data) ->
    @_post name, data

  register: (name, callback) ->
    @subscribers.push { name: name, callback: callback }

  # Internal method only. Called by iOS part for triggering events on the bus
  raise: (name, data) ->
    parsedData = null
    if data instanceof Array or data instanceof Object or (typeof data == "string" or data instanceof String)
      # Data are already parsed, nothing to do
      parsedData = data
    else
      parsedData = JSON.parse data
    for e in @subscribers
      e.callback(name, parsedData) if e.name == name

  @getDefault: ->
    unless Caravel.default?
      Caravel.default = new Caravel("default")
      Caravel.default.post "CaravelInit"
    Caravel.default

  @get: (name) ->
    for b in Caravel.buses
      if b.getName() == name
        return b

    b = new Caravel name
    Caravel.buses.push b
    b.post "CaravelInit"
    return b
