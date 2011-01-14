
$ -> 

    # Write incoming messages to the page and scroll.
    socket = new io.Socket()
    socket.on "message", (data) ->
        data = JSON.parse data
        $("#messages").append "<p>#{data.message}</p>"
        if data.users?
            heading = "<li><h2>Users</h2> (#{data.users.length})</li>"
            users = ("<li>#{user}</li>" for user in data.users).join("")
            $("#users").html heading + users
            button = $("#button")
            if button.attr("value") is button.attr("defaultValue")
                button.attr "value", "Send Message"
                $("#leave, #users").show()
                
        window.scrollBy 0, 10000
    socket.connect()
    
    # On first submit, change the submit button text and 
    # show the leave button.
    $("#input").submit ->
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
    $("#leave").click ->
        socket.disconnect()
        location.href = "/"
