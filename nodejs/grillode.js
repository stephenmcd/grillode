
var net = require('net');
var querystring = require('querystring');
var settings = require('./settings.js');
var util = require('./util.js');


// Main user data - uuid/socket mapping of all connections.
var sockets = {};


var message = function(data, from, to) {
    /*
    Sends the given data to each of the user connections.
    */
    if (from) {
        data = from + ': ' + data;
    }
    var timeStamp = util.timeStamp();
    var text = timeStamp + util.stripTags(data);
    var html = util.template('message.html', {
        message: timeStamp + util.stripTags(data, settings.ALLOWED_TAGS)
    });
    for (var uuid in sockets) {
        if (sockets[uuid].http) {
            if (sockets[uuid].name) {
                sockets[uuid].write(html);
            }
        } else if (sockets[uuid].name && sockets[uuid].name != from) {
            sockets[uuid].write(text + '\n');
        }
    }
    util.log(data);
};

var joins = function(name) {
    /*
    Send the message when a user joins.
    */
    message(name + ' joins');
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
        socket.name = '';
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
                var queryAt = data.indexOf('?');
                var newLineAt = data.indexOf('\n');
                var lastSpaceAt = data.lastIndexOf(' ', newLineAt);
                data = data.substr(queryAt + 1, lastSpaceAt - queryAt - 1);
                data = querystring.parse(data);
                if (!sockets[data.uuid].name) {
                    sockets[data.uuid].name = data.message;
                    joins(data.message);
                } else {
                    message(data.message, sockets[data.uuid].name);
                }
            }
        } else {
            // Direct connection.
            if (!socket.name) {
                socket.name = data;
                joins(data);
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
