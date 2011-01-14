
express  = require "express"
utils    = require "./utils"
settings = require "./settings"


# Global list of client connections in rooms.
rooms = {}
rooms[room] = [] for room in settings.ROOMS

    
# Adds a client to a room.
add = (client, room) -> 
    client.room = room
    rooms[room].push client

# Removes a client from a room.
remove = (client) -> 
    room = client.room
    index = rooms[room].indexOf client
    rooms[room].splice index, 1

# Send the given message string to all clients for the given room.
broadcast = (room, message) -> 
    data = 
        users: c.name for c in rooms[room]
        message: "[#{utils.time()}] #{message}"
    data = JSON.stringify data
    c.send data for c in rooms[room]


# Set up the express app.
app = express.createServer()
app.use express.staticProvider root: "#{__dirname}/public"
app.register ".coffee", require("coffeekup")
app.set "view options", layout: off

# Hompage that lists users in each room.
app.get "/", (req, res) -> 
    res.render "index.coffee", context: rooms: rooms

# A single room.
app.get "/room/:room", (req, res) -> 
    res.render "room.coffee", context: room: req.params.room

app.get "/client.coffee", (req, res) ->
    res.header "Content-Type", "text/plain"
    res.send utils.coffeeCompile "client.coffee"

app.listen settings.PORT


# Set up socket.io events.
((require "socket.io").listen app).on "connection", (client) ->

    client.on "message", (data) ->
        try
            data = JSON.parse data
        catch e
            return
        text = utils.stripTags data.message
        html = utils.stripTags data.message, settings.ALLOWED_TAGS
        room = data.room
        # Bail out if any data is missing.
        if not rooms[room]? or not text
            return
        if not client.name?
            # Client has not yet entered a name.
            if rooms[room].some ((c) -> c.name is text)
                # Name given is already in use.
                message = message: "Name is in use, please enter another"
                client.send JSON.stringify message
            else
                # Set the client's name and send the join message.
                add client, room
                client.name = text
                client.displayName = html
                broadcast client.room, "#{client.displayName} joins"
        else
            # Client sent a message.
            broadcast client.room, "#{client.displayName}: #{html}"

    client.on "disconnect", ->
        # On disconnect, send the leave message and remove the client 
        # from the global client list.
        if client.name?
            name = client.displayName
            room = client.room
            remove client
            broadcast room, "#{name} leaves"
