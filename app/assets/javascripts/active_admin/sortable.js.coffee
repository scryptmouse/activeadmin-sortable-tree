#= require jquery.ui.sortable
#= require jquery.mjs.nestedSortable

window.ActiveAdminSortableEvent = do ->
  eventToListeners = {}

  return {
    add: (event, callback) ->
      if not eventToListeners.hasOwnProperty(event)
        eventToListeners[event] = []
      eventToListeners[event].push(callback)

    trigger: (event, args) ->
      if eventToListeners.hasOwnProperty(event)
        for callback in eventToListeners[event]
          try
            callback.call(null, args)
          catch e
            console.error(e) if console and console.error
  }

$ ->

  $('.disclose').bind 'click', (event) ->
    $(this).closest('li').toggleClass('mjs-nestedSortable-collapsed').toggleClass('mjs-nestedSortable-expanded')

  $("[data-sortable-type=plain]").each ->
    $this = $(@)
    $this.sortable
      revert: 250
      update: ->
        $this.sortable("disable")
        $.ajax
          url: $this.data("sortable-url")
          type: "post"
          data: $this.sortable("serialize")
        .always ->
          $this.sortable("enable")
          ActiveAdminSortableEvent.trigger('ajaxAlways')
        .done ->
          ActiveAdminSortableEvent.trigger('ajaxDone')
        .fail ->
          ActiveAdminSortableEvent.trigger('ajaxFail')

    .disableSelection()

  status_tag = (message, status_class = 'error') ->
    "<span class='status_tag #{status_class}'>#{message}</span>"

  $(".index_as_sortable [data-sortable-type]").each ->
    $this = $(@)
    if $this.data('sortable-type') == "tree"
      max_levels = $this.data('max-levels')
      tab_hack = 20 # nestedSortable default
    else
      max_levels = 1
      tab_hack = 99999

    $this.nestedSortable
      forcePlaceholderSize: true
      forceHelperSizeType: true
      errorClass: 'cantdoit'
      disableNesting: 'cantdoit'
      handle: '> .item'
      listType: 'ol'
      items: 'li'
      opacity: .6
      placeholder: 'placeholder'
      revert: 250
      maxLevels: max_levels,
      tabSize: tab_hack
      protectRoot: $this.data('protect-root')
      # prevent drag flickers
      tolerance: 'pointer'
      toleranceElement: '> div'
      isTree: true
      startCollapsed: $this.data("start-collapsed")
      update: (event, ui) ->
        $this.nestedSortable("disable")

        $this.find('.status_message').empty()

        $.ajax
          url: $this.data("sortable-url")
          type: "post"
          data: $this.nestedSortable("serialize")
          dataType: 'json'
          beforeSend: (xhr) ->
            # Avoid 'no element found' error on HTTP 204 in Firefox.
            xhr.overrideMimeType 'text/plain; charset=x-user-defined'
        .always ->
          $this.find('.item').each (index) ->

            if index % 2
              $(this).removeClass('odd').addClass('even')
            else
              $(this).removeClass('even').addClass('odd')

          $this.nestedSortable("enable")

          ActiveAdminSortableEvent.trigger('ajaxAlways')
        .done ->
          ActiveAdminSortableEvent.trigger('ajaxDone')
        .fail (xhr) ->
          response_text = xhr.responseText

          status_message_content = if response_text[0] == '['
            $.map($.parseJSON(response_text), status_tag).join("")
          else
            status_tag response_text

          $(ui.item).find('.status_message').html status_message_content

          $this.sortable('cancel')

          ActiveAdminSortableEvent.trigger('ajaxFail')
