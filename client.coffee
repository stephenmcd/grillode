
$ ->

    socket = new io.Socket()
    title = $("title").text()
    away = no
    connected = no

    # Write incoming messages to the page and scroll.
    socket.on "message", (data) ->

        data = JSON.parse data
        win = $ window
        doc = $ window.document
        bottom = win.scrollTop() + win.height() is doc.height()
        $("#messages").append "<p>#{data.message}</p>"

        # Increment the number of missed messages in the title
        # if the user is away.
        if away
            messages = parseFloat($("title").text().substr 1) + 1
            messages += " message" + (if messages isnt 1 then "s" else "")
            $("title").text "(#{messages}) " + title

        if bottom
            window.scrollBy 0, 10000

        if data.users?
            connected = yes
            heading = "<li><h2>Users</h2> (#{data.users.length})</li>"
            users = ("<li>#{user}</li>" for user in data.users).join("")
            $("#users").html heading + users
            button = $("#button")
            if button.attr("value") is button.attr("defaultValue")
                button.attr "value", "Send Message"
                $("#users").show()

    # Send the room name once connected.
    socket.on "connect", ->
        socket.send JSON.stringify room: $("#room").attr "value"

    socket.connect()

    # On first submit, change the submit button text and
    # show the leave button.
    $("#input").submit ->
        socket.send JSON.stringify message: this.message.value
        this.message.value = ""
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

    # Set away when the window loses focus, and prefix the title
    # with a counter for missed messages.
    $(window).blur ->
        away = yes
        if connected and ($("title").text().indexOf title) is 0
            $("title").text("(0 messages) " + title)

    # Set not away when the window gains focus, and restore the title.
    $(window).focus ->
        away = no
        if ($("title").text().indexOf title) isnt 0
            $("title").text title
