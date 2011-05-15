
coffee     = require "coffee-script"
express    = require "express"
fs         = require "fs"
markdown   = (require "node-markdown").Markdown
path       = require "path"
settings   = require "./settings"
uid        = (require "connect").utils.uid


# Set up the express app.
app = express.createServer()
app.use express.bodyDecoder()
if settings.LOGGING
    app.use express.logger()
app.use express.staticProvider root: path.join __dirname, "public"
app.set "view options", locals: i: 0
app.register ".coffee", require "coffeekup"


# Homepage - redirect to the default URL.
app.get "/", (req, res) ->
    res.redirect(settings.DEFAULT_URL)

# About - parses README.md and pass it to the empty template.
app.get "/about", (req, res) ->
    fs.readFile (path.join __dirname, "README.md"), (err, data) ->
        about = (markdown String data).replace "<h1>Overview</h1>", ""
        context = title: "About", about: about
        res.render "about.coffee", context: context

# Form for adding a named room.
app.all "/rooms/add", (req, res) ->
    room = message = ""
    if req.body?.room?
        room = req.body.room.trim().substr 0, settings.MAX_ROOMNAME_LENGTH
        if process.rooms[room]?
            message = "Room already exists, please choose another name"
        else
            res.redirect "/rooms/#{room}"
    context = title: "Add room", room: room, message: message
    res.render "add_room.coffee", context: context

# Main view for a room.
app.get "/rooms/:room", (req, res) ->
    room = req.params.room
    private = room not in settings.ROOMS and not settings.ADDABLE_ROOMS_VISIBLE
    title = if private then "Private" else room
    context = title: title, room: room
    res.render "room.coffee", context: context, layout: false

# Lists rooms and users in each room.
app.get "/rooms", (req, res) ->
    if settings.ADDABLE_ROMS_VISIBLE
        visibleRooms = process.rooms
    else
        visibleRooms = {}
        for room, users of process.rooms when not process.rooms[room]?.dynamic
            visibleRooms[room] = users
    context = title: "Home", rooms: visibleRooms
    res.render "rooms.coffee", context: context

# Starts a matchup room - a randomly named private room that goes into
# the matchup list while waiting for someone else to join.
app.get "/wait", (req, res) ->
    room = uid settings.MAX_ROOMNAME_LENGTH, layout: false
    res.redirect "/rooms/#{room}"

# Lists the users waiting in matchup rooms.
app.get "/waiting", (req, res) ->
    since = (date) -> Math.ceil ((new Date).getTime() - date.getTime()) / 60000
    clients = (process.rooms[room][0] for room in process.matchups)
    context = title: "Waiting", clients: clients, since: since
    res.render "waiting.coffee", context: context

# Join the earliest created dynamic room someone is waiting in, eg first in
# the matchup list.
app.get "/match", (req, res) ->
    if room = process.matchups.shift()
        res.redirect "/rooms/#{room}"
    else
        context = title: "Match"
        res.render "no_match.coffee", context: context

# Chatroulette style matchup - if there is a room in the matchup list, join
# it, otherwise create a dynamic room that will go into the matchup list.
app.get "/random", (req, res) ->
    if room = process.matchups.shift()
        res.redirect "/rooms/#{room}"
    else
        res.redirect "/wait"

# Hosts the client-side Coffeescript converting it to Javascript.
app.get "/client.coffee", (req, res) ->
    fs.readFile (path.join __dirname, "client.coffee"), (err, data) ->
        if not err
            try
                data = coffee.compile String data
            catch err
        if err
            data = "alert(\"#{err}\");"
        res.header "Content-Type", "text/plain"
        res.send data

exports.app = app
