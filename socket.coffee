
stripTags  = (require "./html").stripTags
markdown   = (require "node-markdown").Markdown
settings   = require "./settings"


# Convenience method for removing an item from an array.
Array.prototype.remove = (item) ->
    if item in this
        index = this.indexOf item
        this.splice index, 1

# Send the given message string to all clients for the given room.
broadcast = (room, message, addr) ->
    datetime = (new Date).toUTCString()
    time = (datetime.split(" ").filter (s) -> (s.indexOf ":") isnt -1)[0]
    data =
        users: c.name for c in process.rooms[room]
        message: "[#{time}] #{message}"
    data = JSON.stringify data
    c.send data for c in process.rooms[room]
    if settings.LOGGING
        output = "#{addr} - - [#{datetime}] \"#{room} #{message}\" - - - -\n"
        process.stdout.write output

# Passed to socket.io in server.coffee to handle each socket connection.
exports.handler = (client) ->

    client.on "message", (data) ->
        data = JSON.parse data
        if data.room? and not client.room?
            # Initial connection on load of room view.
            room = data.room.trim().substr 0, settings.MAX_ROOMNAME_LENGTH
            if not process.rooms[room]?
                if settings.ADDABLE_ROOMS
                    process.rooms[room] = []
                    process.rooms[room].dynamic = yes
                else
                    return
            client.start = new Date()
            client.room = room
            client.addr = client.request.socket.remoteAddress
        else if data.message? and client.room? and process.rooms[client.room]?
            message = data.message.trim()
            text = (stripTags message).substr 0, settings.MAX_USERNAME_LENGTH
            html = stripTags (markdown message), settings.ALLOWED_TAGS
            room = client.room
            addr = client.addr
            # Bail out if any data is missing.
            if not text
                return
            if not client.name?
                # Client has not yet entered a name.
                taken = no
                if process.rooms[room]?
                    taken = text in (c.name for c in process.rooms[room])
                if taken
                    # Name given is already in use.
                    message = message: "Name is in use, please enter another"
                    client.send JSON.stringify message
                else
                    # Add the client to the room, set the client's name
                    # and send the join message.
                    empty = process.rooms[room].length is 0
                    if process.rooms[room]?.dynamic and empty
                        process.matchups.push room
                    client.name = text
                    client.displayName = html
                    process.rooms[room].push client
                    broadcast client.room, "#{client.displayName} joins", addr
            else
                # Client sent a message.
                broadcast client.room, "#{client.displayName}: #{html}", addr

    client.on "disconnect", ->
        {displayName, room} = client
        joined = displayName?
        dynamic = process.rooms[room]?.dynamic
        users = process.rooms[room]?.length
        addr = client.addr
        if joined
            # Client had joined a room - send the leave message and
            # remove the client from the room.
            process.rooms[room].remove client
            broadcast room, "#{displayName} leaves", addr
        if joined and room in process.matchups
            # Client created the matchup room without anyone else
            # joining it, so remove it from the matchup list.
            process.matchups.remove room
        if not joined and dynamic and users is 1
            # Client was assigned to a matchup room but didn't
            # actually join, so return the room to the front of
            # the matchup list.
            process.matchups.unshift room
        if dynamic and users is 0
            # Remove a dynamically created room when it is empty.
            delete process.rooms[room]
