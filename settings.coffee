

# Tag/attribs mapping of allowed tags and attributes.
exports.ALLOWED_TAGS = 
    b       : []
    i       : [] 
    img     : ["src"]
    a       : ["href"] 
    center  : []
    font    : ["face", "color", "size"]

# Maximum name length.
exports.MAX_NAME_LENGTH = 30

# List of available rooms.
exports.ROOMS = ["Lobby", "Library", "Dining", "Casino", "Gym", "Nightclub"]

# Port the server will listen on.
exports.PORT = if isNaN process.argv[2] then 8000 else process.argv[2]
