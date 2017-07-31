session.input.readAsXML(function(error, xml) {
    if (error) {
        // handle error
    } else {
        var option = { omitXmlDeclaration: false };
        var output = XML.stringify(option, xml);
        var DOM = XML.parse(output);

        var json = JSON.stringify(xmlToJson(DOM));
        var hm = require('header-metadata');
        var headers = hm.current; //  The headers variable refers to the hm.current object.

        headers.set('Content-Type', 'application/json');
        session.output.write(json); // write to the output context.
    }
})

function xmlToJson(xml) {

    // Create the return object
    var obj = {};

    // text node
    if (4 === xml.nodeType) {
        obj = xml.nodeValue;
    }

    if (xml.hasChildNodes()) {
        for (var i = 0; i < xml.childNodes.length; i++) {
            var TEXT_NODE_TYPE_NAME = '#text',
                item = xml.childNodes.item(i),
                nodeName = item.nodeName,
                content;

            if (TEXT_NODE_TYPE_NAME === nodeName) {
                //single textNode or next sibling has a different name
                if ((null === xml.nextSibling) || (xml.localName !== xml.nextSibling.localName)) {
                    content = xml.textContent;

                    //we have a sibling with the same name
                } else if (xml.localName === xml.nextSibling.localName) {
                    //if it is the first node of its parents childNodes, send it back as an array
                    content = (xml.parentElement.childNodes[0] === xml) ? [xml.textContent] : xml.textContent;
                }
                return content;
            } else {
                if ('undefined' === typeof(obj[nodeName])) {
                    obj[nodeName] = xmlToJson(item);
                } else {
                    if ('undefined' === typeof(obj[nodeName].length)) {
                        var old = obj[nodeName];
                        obj[nodeName] = [];
                        obj[nodeName].push(old);
                    }

                    obj[nodeName].push(xmlToJson(item));
                }
            }
        }
    }
    return obj;
}
