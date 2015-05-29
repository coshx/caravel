# @class Caravel
# @brief Caravel JS bus
class Caravel
  @default = null
  @buses = []

  constructor: (name)  ->
    @name = name
    @subscribers = []

    # JS bus is ready, notify Swift counterpart
    @_post "CaravelInit", null

  # Internal method for posting
  _post: (eventName, data) ->
    # TODO: Improve that code using an AJAX request
    iframe = document.createElement 'iframe'
    src = "caravel@#{@name}@#{eventName}"
    src += "@#{data}" if data?
    iframe.setAttribute 'src', src
    document.documentElement.appendChild iframe
    iframe.parentNode.removeChild iframe

  getName: () ->
    @name

  post: (name, data) ->
    @_post name, data

  register: (name, callback) ->
    @subscribers.push { name: name, callback: callback }

  # Internal method only. Called by iOS part for triggering events on the bus
  raise: (name, data) ->
    if data instanceof Array or data instanceof Object
      # Data are already parsed, nothing to do
      parsedData = data
    else
      parsedData = JSON.parse data
    for e in @subscribers
      e.callback(name, parsedData) if e.name == name

  @getDefault: ->
    Caravel.default = new Caravel("default") unless Caravel.default?
    Caravel.default

  @get: (name) ->
    for b in Caravel.buses
      if b.getName() == name
        return b

      b = new Caravel(name)
      Caravel.buses.push b
      return b
