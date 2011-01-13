
$ -> 

    # Write incoming messages to the page and scroll.
    socket = new io.Socket()
    socket.on "message", (data) ->
        $("#messages").append "<p>#{data}</p>"
        window.scrollBy 0, 10000
    socket.connect()
    
    # On first submit, change the submit button text and 
    # show the leave button.
    $("#input").submit ->
        if this.button.value is this.button.defaultValue
            this.button.value = "Send Message"
            $(this.leave).show()
        data = 
            room: this.room.value
            message: this.message.value
        socket.send JSON.stringify data
        this.message.value = ''
        this.message.focus()
        false
    
    # Clear the input box when first focused.
    $("#message").focus ->
        if this.value is this.defaultValue
            this.value = ""

    # Go to the homepage when the leave button is clicked.
    $(".leave").click ->
        socket.disconnect()
        location.href = "/"
