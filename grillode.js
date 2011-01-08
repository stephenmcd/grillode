
var fs = require('fs');
var http = require('http');
var htmlparser = require('./htmlparser');
var net = require('net');
var path = require('path');
var querystring = require('querystring');
var sys = require('sys');


var allowedTags = {
    b: [], 
    i: [], 
    img: ['src'], 
    a: ['href'], 
    center: [],
    font: ['face', 'color', 'size'],
};

var httpInitialStream = '';
while (httpInitialStream.length < 20000) {
    httpInitialStream += '\n';
}

var port = 8000;
if (process.argv.length > 2 && !isNaN(process.argv[2])) {
    port = Number(process.argv[2]);
}

var sockets = {};

var stripTags = function(html, allowed) {
    /*
    Strips the given HTML string of all tags, other than those 
    specified in the ``allowed`` param, which should be in the 
    format: {tag1: [allowedAttribute1, allowedAttribute2], tag2: []}
    */
    
    // Bail out early if no HTML.
    if (html.indexOf('<') == -1) {
        return html;
    }

    var handler = new htmlparser.DefaultHandler();
    var parser = new htmlparser.Parser(handler);

    parser.parseComplete(html);
    allowed = allowed || {};

    var build = function(parts) {
        /*
        Takes a list of dom nodes and returns each node as a string 
        if it's text or an allowed tag. Called recursively on the 
        node's child nodes.
        */
        return parts.map(function(part) {
            var children = part.children ? build(part.children) : '';
            switch (part.type) {
                case 'text':
                    return part.data;
                case 'tag':
                    var attribs = allowed[part.name];
                    if (typeof attribs != 'undefined') {
                        attribs = attribs.map(function(name) {
                            var value = part.attribs[name];
                            if (value) {
                                value = value.replace(/"/g, escape('"'));
                                return ' ' + name + '="' + value + '"';
                            }
                            return '';
                        }).join('');
                        var start = '<' + part.name + attribs + '>';
                        var end = '</' + part.name + '>';
                        return start + children + end;
                    }
            }
            return children;
        }).join('');
    };

    return build(handler.dom);

};

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

var timeStamp = function() {
    var d = new Date();
    var timeParts = [d.getHours(), d.getMinutes(), d.getSeconds()];
    var timeStamp = timeParts.map(function(t) {
        return String(t).length == 1 ? '0' + t : t;
    }).join(':');
    return '[' + timeStamp + '] ';
};

var log = function(data) {
    sys.puts(timeStamp() + data);
};

var message = function(data, from, to) {
    if (from) {
        data = from + ': ' + data;
    }
    var text = timeStamp() + stripTags(data);
    var templateVars = {message: timeStamp() + stripTags(data, allowedTags)};
    var html = template('message.html', templateVars);
    for (var uuid in sockets) {
        if (sockets[uuid].http) {
            if (sockets[uuid].name) {
                sockets[uuid].write(html);
            }
        } else if (sockets[uuid].name && sockets[uuid].name != from) {
            sockets[uuid].write(text + '\n');
        }
    }
    log(data);
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

    socket.on("error", function(e) {
        log('error: ' + e);
    });

}).listen(port);
