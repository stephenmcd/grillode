
var net = require('net');
var querystring = require('querystring');
var settings = require('./settings.js');
var util = require('./util.js');


// Main user data - uuid/socket mapping of all connections.
var sockets = {};

// Store names for linear lookup.
var names = {};


var message = function(data, from, to) {
    /*
    Sends the given data to each of the connected sockets.
    */
    if (from) {
        data = from + ': ' + data;
    }
    var timeStamp = util.timeStamp();
    var text = timeStamp + util.stripTags(data) + '\n';
    var html = util.template('message.html', {
        message: timeStamp + util.stripTags(data, settings.ALLOWED_TAGS)
    });
    for (var uuid in sockets) {
        if (sockets[uuid].joined) {
            if (sockets[uuid].http) {
                sockets[uuid].write(html);
            } else if (sockets[uuid].name != from) {
                sockets[uuid].write(text);
            }
        }
    }
    util.log(data);
};

var join = function(socket, name) {
    /*
    Called when a user enters their name. Strip the name down to 
    text and HTML, and ensure the name isn't taken. If not taken, 
    send a join message, otherwise ask the user for their name again.
    */
    var text = util.stripTags(name);
    socket.joined = text && !names[text]
    if (socket.joined) {
        names[text] = true;
        socket.nameText = text;
        socket.name = util.stripTags(name, settings.ALLOWED_TAGS);
        message(socket.name + ' joins');
    } else {
        var response = 'The name entered is taken, please enter another';
        if (socket.http) {
            socket.write(util.template('message.html', {message: response}));
        } else {
            socket.write(response + '\n');
        }
    }
};

var leaves = function(name) {
    /*
    Send the message when a user leaves.
    */
    message(name + ' leaves');
};

var httpStreamStart = function(socket) {
    /*
    Called when a user makes their first HTTP request. Renders the 
    main template and initiates streaming.
    */
    var html = util.template('index.html', {
        uuid: querystring.escape(socket.uuid)
    });
    socket.write(html);
    var streamer = function(first) {
        try {
            if (first) {
                socket.write(settings.HTTP_INITIAL_STREAM);
            } else {
                socket.write('\n');
            }
        } catch (e) {
            return;
        }
        setTimeout(streamer, 30000);
    };
    setTimeout(function() {
        streamer(true);
    }, 1000);
};

net.createServer(function(socket) {

    socket.on("connect", function() {
        /*
        Assign some custom attributes to the socket when first 
        connected. Set a timeout requesting a username to be entered 
        which will only occur for direct connections since a HTTP 
        request will provide data as it connects and the custom 
        ``http`` attribute on the socket will be set to true.
        */
        socket.setTimeout(0);
        socket.uuid = util.uuid();
        socket.http = false;
        socket.joined = false;
        socket.nameText = '';
        socket.nameHtml = '';
        sockets[socket.uuid] = socket;
        setTimeout(function() {
            if (!socket.http) {
                socket.write('Please enter your name: ');
            }
        }, 100);
    });

    socket.on("data", function(data) {
        /*
        Handle incoming data for either HTTP or direct connections.
        The first time user input is provided for a connection, it's 
        used as the user's name.
        */
        data = data.toString().trim(); 
        socket.http = data.indexOf('GET /') == 0;
        if (socket.http) {
            if (data.indexOf('?') == -1) {
                httpStreamStart(socket);
            } else {
                // Querystring should contain ``uuid`` and ``message``.
                var query = util.queryStringFromRequest(data);
                if (!sockets[query.uuid]) {
                    // TODO: Handle stale uuid with JSON back to client.
                } else {
                    if (!sockets[query.uuid].joined) {
                        join(sockets[query.uuid], query.message);
                    } else {
                        message(query.message, sockets[query.uuid].name);
                    }
                }
            }
        } else {
            // Direct connection.
            if (!socket.joined) {
                join(socket, data);
            } else {
                message(data, socket.name);
            }
        }
    });

    socket.on("close", function() {
        /*
        Send the ``leaves`` message when a connection is closed, 
        and remove the connection from the main socket mapping.
        */
        var name = sockets[socket.uuid].name;
        delete names[socket.rawName];
        delete sockets[socket.uuid];
        if (name) {
            leaves(name);
        }
    });

    socket.on("error", function(e) {
        /*
        Implementing this error handler ensures socket errors aren't 
        raised, which brings down the entire script.
        */
        util.log('error: ' + e);
    });

}).listen(settings.PORT);
