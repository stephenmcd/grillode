
express  = require "express"
settings = require "./settings"
utils    = require "./utils"


# Global list of client connections in rooms.
rooms = {}
rooms[room] = [] for room in settings.ROOMS


# Send the given message string to all clients for the given room.
broadcast = (room, message) -> 
    data = 
        users: c.name for c in rooms[room]
        message: "[#{utils.time()}] #{message}"
    data = JSON.stringify data
    c.send data for c in rooms[room]    

# Expose connect's uid function which is available as an express dependency.
uid = (require "connect").utils.uid

# Returns true if a room is dynamic (eg not defined in settings.ROOMS)
dynamic = (room) -> room not in settings.ROOMS


# Set up the express app.
app = express.createServer()
app.use express.logger()
app.use express.staticProvider root: (require "path").join __dirname, "public"
app.register ".coffee", require "coffeekup"
app.set "view options", layout: off

# Hompage that lists users in each room.
app.get "/", (req, res) -> 
    staticRooms = {}
    for room, users of rooms when not dynamic room
        staticRooms[room] = users
    res.render "index.coffee", context: (rooms: staticRooms), locals: i: 0

# A single room.
app.get "/room/:room", (req, res) ->
    room = req.params.room
    title = if dynamic room then "Private" else room
    res.render "room.coffee", context: room: room, title: title

# Start a dynamic room.
app.get "/start", (req, res) ->
    res.redirect("room/#{uid(20)}")

app.get "/client.coffee", (req, res) ->
    res.header "Content-Type", "text/plain"
    res.send utils.coffeeCompile "client.coffee"

app.listen settings.PORT


# Set up socket.io events.
((require "socket.io").listen app).on "connection", (client) ->

    client.on "message", (data) ->
        if not client.room?
            # Initial connection on load of room template.
            room = data.substr 0, settings.MAX_ROOMNAME_LENGTH
            if not rooms[room]?
                if settings.ADDABLE_ROOMS
                    rooms[room] = []
                else
                    return
            client.room = room
        else
            text = utils.stripTags data
            text = text.substr 0, settings.MAX_USERNAME_LENGTH
            html = utils.stripTags data, settings.ALLOWED_TAGS
            room = client.room
            # Bail out if any data is missing.
            if not text
                return
            if not client.name?
                # Client has not yet entered a name.
                if rooms[room]? and text in (c.name for c in rooms[room])
                    # Name given is already in use.
                    message = message: "Name is in use, please enter another"
                    client.send JSON.stringify message
                else
                    # Add the client to the room, set the client's name 
                    # and send the join message.
                    client.name = text
                    client.displayName = html
                    rooms[room].push client
                    broadcast client.room, "#{client.displayName} joins"
            else
                # Client sent a message.
                broadcast client.room, "#{client.displayName}: #{html}"

    client.on "disconnect", ->
        # On disconnect, send the leave message and remove the client 
        # from the room.
        if client.name?
            {displayName, room} = client
            rooms[room].splice (rooms[room].indexOf client), 1
            broadcast room, "#{displayName} leaves"
            # Remove a dynamically created room when it is empty.
            if rooms[room]?.length is 0 and dynamic room
                delete rooms[room]
