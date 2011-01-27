
express  = require "express"
io       = require "socket.io"
settings = require "./settings"
utils    = require "./utils"


# Convenience method for removing an item from an array.
Array.prototype.remove = (item) -> 
    if item in this
        index = this.indexOf item
        this.splice index, 1


# Global mapping of room names to lists of client connections for rooms.
rooms = {}
rooms[room] = [] for room in settings.ROOMS

# Global queue of room names for random matchups. Added to when a user 
# starts a new room, and pulled from when another user joins that room. 
# Allows for chatroulette style random matchups, or a customer support 
# type of service.
matchups = []


# Send the given message string to all clients for the given room.
broadcast = (room, message, addr) -> 
    data = 
        users: c.name for c in rooms[room]
        message: "[#{utils.time()}] #{message}"
    data = JSON.stringify data
    c.send data for c in rooms[room]    
    if settings.LOGGING
        timestamp = (new Date).toUTCString()
        output = "#{addr} - - [#{timestamp}] \"#{room} #{message}\" - - - -\n"
        process.stdout.write output


# Set up the express app.
app = express.createServer()
app.use express.bodyDecoder()
if settings.LOGGING
    app.use express.logger()
app.use express.staticProvider root: (require "path").join __dirname, "public"
app.set "view options", locals: i: 0
app.register ".coffee", require "coffeekup"

# Homepage - redirect to the default URL.
app.get "/", (req, res) -> 
    res.redirect(settings.DEFAULT_URL)

# Form for adding a named room.
app.all "/rooms/add", (req, res) -> 
    room = message = ""
    if req.body?.room?
        room = req.body.room.trim().substr 0, settings.MAX_ROOMNAME_LENGTH
        if rooms[room]?
            message = "Room already exists, please choose another name"
        else
            res.redirect "/rooms/#{room}"
    context = title: "Add room", room: room, message: message
    res.render "add_room.coffee", context: context

# Main view for a room.
app.get "/rooms/:room", (req, res) ->
    room = req.params.room
    private = rooms[room]?.dynamic and not settings.ADDABLE_ROOMS_VISIBLE
    title = if private then "Private" else room
    context = title: title, room: room
    res.render "room.coffee", layout: false, context: context

# Lists rooms and users in each room.
app.get "/rooms", (req, res) -> 
    if settings.ADDABLE_ROOMS_VISIBLE
        visibleRooms = rooms
    else
        visibleRooms = {}
        for room, users of rooms when not rooms[room]?.dynamic
            visibleRooms[room] = users
    context = title: "Home", rooms: visibleRooms
    res.render "rooms.coffee", context: context

# Starts a matchup room - a randomly named private room that goes into 
# the matchup list while waiting for someone else to join.
app.get "/wait", (req, res) ->
    room = utils.uid settings.MAX_ROOMNAME_LENGTH
    res.redirect "/rooms/#{room}"

# Join the earliest created dynamic room someone is waiting in, eg first in 
# the matchup list.
app.get "/match", (req, res) ->
    if room = matchups.shift()
        res.redirect "/rooms/#{room}"
    else
        context = title: "Match"
        res.render "no_match.coffee", context: context

# Chatroulette style matchup - if there is a room in the matchup list, join 
# it, otherwise create a dynamic room that will go into the matchup list.
app.get "/random", (req, res) ->
    if room = matchups.shift()
        res.redirect "/rooms/#{room}"
    else
        res.redirect "/wait"

# Hosts the client-side Coffeescript converting it to Javascript.
app.get "/client.coffee", (req, res) ->
    res.header "Content-Type", "text/plain"
    res.send utils.coffeeCompile "client.coffee"

app.listen settings.PORT


# Set up socket.io events.
socket = io.listen app
socket.options.log = -> null
socket.on "connection", (client) ->
    
    client.on "message", (data) ->
        data = JSON.parse data
        if data.room? and not client.room?
            # Initial connection on load of room view.
            room = data.room.trim().substr 0, settings.MAX_ROOMNAME_LENGTH
            if not rooms[room]?
                if settings.ADDABLE_ROOMS
                    rooms[room] = []
                    rooms[room].dynamic = true
                else
                    return
            client.room = room
            client.addr = client.request.socket.remoteAddress
        else if data.message? and client.room? and rooms[client.room]?
            text = utils.stripTags data.message.trim()
            text = text.substr 0, settings.MAX_USERNAME_LENGTH
            html = utils.stripTags data.message.trim(), settings.ALLOWED_TAGS
            room = client.room
            addr = client.addr
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
                    if rooms[room]?.dynamic and rooms[room].length is 0
                        matchups.push room
                    client.name = text
                    client.displayName = html
                    rooms[room].push client
                    broadcast client.room, "#{client.displayName} joins", addr
            else
                # Client sent a message.
                broadcast client.room, "#{client.displayName}: #{html}", addr

    client.on "disconnect", ->
        {displayName, room} = client
        joined = displayName?
        dynamic = rooms[room]?.dynamic
        users = rooms[room]?.length
        addr = client.addr
        if joined
            # Client had joined a room - send the leave message and 
            # remove the client from the room.
            rooms[room].remove client
            broadcast room, "#{displayName} leaves", addr
        if joined and room in matchups
            # Client created the matchup room without anyone else 
            # joining it, so remove it from the matchup list.
            matchups.remove room
        if not joined and dynamic and users is 1
            # Client was assigned to a matchup room but didn't 
            # actually join, so return the room to the front of 
            # the matchup list.
            matchups.unshift room
        if dynamic and users is 0
            # Remove a dynamically created room when it is empty.
            delete rooms[room]
