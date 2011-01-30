
app      = (require "./app").app
io       = require "socket.io"
settings = require "./settings"


# Global mapping of room names to lists of client connections for rooms.
process.rooms = {}
process.rooms[room] = [] for room in settings.ROOMS

# Global queue of room names for random matchups. Added to when a user 
# starts a new room, and pulled from when another user joins that room. 
# Allows for chatroulette style random matchups, or a customer support 
# type of service.
process.matchups = []

# Start app.
app.listen settings.PORT

# Set up socket.io.
socket = io.listen app
socket.options.log = -> null
socket.on "connection", (require "./socket").handler
