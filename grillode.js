
var net = require('net');
var querystring = require('querystring');
var settings = require('./settings.js');
var util = require('./util.js');


var sockets = {};


var message = function(data, from, to) {
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
    message(name + ' joins');
};

var leaves = function(name) {
    message(name + ' leaves');
};

net.createServer(function(socket) {

    socket.on("connect", function() {
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
        data = data.toString().trim(); 
        socket.http = data.indexOf('GET /') == 0;
        if (socket.http) {
            if (data.indexOf('?') == -1) {
                var html = util.template('index.html', {
                    uuid: querystring.escape(socket.uuid)
                });
                socket.write(html);
                setTimeout(function() {
                    socket.write(settings.HTTP_INITIAL_STREAM);
                }, 1000);
            } else {
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
            if (!socket.name) {
                socket.name = data;
                joins(data);
            } else {
                message(data, socket.name);
            }
        }
    });

    socket.on("close", function() {
        var name = sockets[socket.uuid].name;
        delete sockets[socket.uuid];
        if (name) {
            leaves(name);
        }
    });

    socket.on("error", function(e) {
        util.log('error: ' + e);
    });

}).listen(settings.PORT);
