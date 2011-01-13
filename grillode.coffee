
util = require "./util.coffee"

# Set up the express app.
app = (require "express").createServer()
app.set "view options", layout: off

app.get "/", (req, res) ->
    res.render "index.ejs"

app.listen 8000

# Global list of client connections.
clients = []

# Tag/attribs mapping of allowed tags and attributes.
allowedTags = 
    b       : []
    i       : [] 
    img     : ["src"]
    a       : ["href"] 
    center  : []
    font    : ["face", "color", "size"]

# Return connections that have a valid name assigned.
validClients = -> clients.filter (client) -> client.name?

# Send the given string of data to all valid clients.
broadcast = (data) -> c.send "[#{util.time()}] #{data}" for c in validClients()

# Set up socket.io events.
((require "socket.io").listen app).on "connection", (client) ->

    # Add client to the global list when connected.
    clients.push client

    client.on "message", (data) ->
        if not client.name?
            # Client has not yet entered a name.
            name = util.stripTags data
            if not name or validClients().some ((c) -> c.name is name)
                # Name given is already in use.
                client.send "Name is in use, please enter another"
            else
                # Set the client's name and send the join message.
                client.name = name
                client.displayName = util.stripTags data, allowedTags
                broadcast "#{client.displayName} joins"
        else
            # Client sent a message.
            message = util.stripTags data, allowedTags
            broadcast "#{client.displayName}: #{message}"

    client.on "disconnect", ->
        # On disconnect, send the leave message and remove the client 
        # from the global client list.
        broadcast "#{client.displayName} leaves"
        delete clients[clients.indexOf client]
