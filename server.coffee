
express = require "express"
util    = require "./util.coffee"


# Tag/attribs mapping of allowed tags and attributes.
allowedTags = 
    b       : []
    i       : [] 
    img     : ["src"]
    a       : ["href"] 
    center  : []
    font    : ["face", "color", "size"]

# Global list of client connections in rooms.
rooms = 
    Lobby       : []
    Library     : []
    Dining      : []
    Casino      : []
    Gym         : []
    Nightclub   : []

    
# Adds a client to a room.
add = (client, room) -> 
    client.room = room
    rooms[room].push client

# Removes a client from a room.
remove = (client) -> 
    room = client.room
    index = rooms[room].indexOf client
    delete rooms[room][index]

# Send the given string of data to all valid clients.
broadcast = (room, data) -> 
    c.send "[#{util.time()}] #{data}" for c in rooms[room]


# Set up the express app.
app = express.createServer()
app.use express.staticProvider root: "#{__dirname}/public"
app.set "view options", layout: off

app.get "/", (req, res) -> 
    res.render "index.ejs", locals: rooms: rooms

app.get "/room/:room", (req, res) -> 
    res.render "room.ejs", locals: room: req.params.room

app.get "/client.coffee", (req, res) ->
    res.header "Content-Type", "text/plain"
    res.send util.coffeeCompile "client.coffee"

app.listen 8000


# Set up socket.io events.
((require "socket.io").listen app).on "connection", (client) ->

    client.on "message", (data) ->
        data = JSON.parse data
        if not client.name?
            # Client has not yet entered a name.
            name = util.stripTags data.message
            room = data.room
            if not name or rooms[room].some ((c) -> c.name is name)
                # Name given is already in use.
                client.send "Name is in use, please enter another"
            else
                # Set the client's name and send the join message.
                add client, room
                client.name = name
                client.displayName = util.stripTags data.message, allowedTags
                broadcast client.room, "#{client.displayName} joins"
        else
            # Client sent a message.
            message = util.stripTags data.message, allowedTags
            broadcast client.room, "#{client.displayName}: #{message}"

    client.on "disconnect", ->
        # On disconnect, send the leave message and remove the client 
        # from the global client list.
        broadcast client.room, "#{client.displayName} leaves"
        remove client
