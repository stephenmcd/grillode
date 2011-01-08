
var fs = require('fs');
var htmlparser = require('./htmlparser');
var path = require('path');
var sys = require('sys');


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
exports.stripTags = stripTags;


var uuid = function() {
    /*
    Returns a unique ID for each user for retrieving a user's socket.
    */
    var uuid = '';
    while (uuid.length < 64) {
        uuid += String.fromCharCode(Math.random() * (126 - 33) + 33);
    }
    return uuid;
};
exports.uuid = uuid;


var template = function(file, vars) {
    /*
    Returns the contents of the given filename relative to this 
    script's path, and replaces the mapping of variables given 
    where each variable name is specified in the format: %name%
    */
    var data = fs.readFileSync(path.join(__dirname, file)).toString();
    for (var name in vars) {
        data = data.replace('%' + name + '%', vars[name]);
    }
    return data;
};
exports.template = template;


var timeStamp = function() {
    /*
    Returns the current time in the string format: [HH:MM:SS]
    */
    var d = new Date();
    var timeParts = [d.getHours(), d.getMinutes(), d.getSeconds()];
    var timeStamp = timeParts.map(function(t) {
        return String(t).length == 1 ? '0' + t : t;
    }).join(':');
    return '[' + timeStamp + '] ';
};
exports.timeStamp = timeStamp;


var log = function(data) {
    /*
    Writes the given string to the terminal with a timestamp.
    */
    sys.puts(timeStamp() + data);
};
exports.log = log;
