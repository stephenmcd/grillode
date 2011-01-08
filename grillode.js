
var fs = require('fs'),
    http = require('http'),
    net = require('net'),
    path = require('path'),
    querystring = require('querystring'),
    sys = require('sys'),
    util = require('util');


var httpInitialStream = '';
while (httpInitialStream.length < 20000) {
    httpInitialStream += '\n';
}

var port = 8000;
if (process.argv.length > 2 && !isNaN(process.argv[2])) {
    port = Number(process.argv[2]);
}

var sockets = {};

var uuid = function() {
    var uuid = '';
    while (uuid.length < 64) {
        uuid += String.fromCharCode(Math.random() * (126 - 33) + 33);
    }
    return uuid;
};

var template = function(file, vars) {
    var data = fs.readFileSync(path.join(__dirname, file)).toString();
    for (var name in vars) {
        data = data.replace('%' + name + '%', vars[name]);
    }
    return data;
};

var message = function(data, from, to) {

    var d = new Date();
    var time = [d.getHours(), d.getMinutes(), d.getSeconds()].map(function(t) {
        return String(t).length == 1 ? '0' + t : t;
    }).join(':');

    if (from) {
        data = from + ': ' + data;
    }
    data = '[' + time + '] ' + data;
    dataHtml = '<table><tr><td>' + data + '</td></tr></table>' + 
               '<script>onMessage();</script>';
    
    for (var uuid in sockets) {
        if (sockets[uuid].http) {
            if (sockets[uuid].name) {
                sockets[uuid].write(dataHtml);
            }
        } else if (sockets[uuid].name && sockets[uuid].name != from) {
                sockets[uuid].write(data + '\n');
        }
    }
    sys.puts(data);

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
        socket.uuid = uuid();
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
                var html = template('index.html', {
                    uuid: querystring.escape(socket.uuid)
                });
                socket.write(html);
                setTimeout(function() {
                    socket.write(httpInitialStream);
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

}).listen(port);
