import Foundation

/// Reads the human-readable text out of an error body, e.g. S3's
/// `<Error><Code>AccessDenied</Code><Message>Access Denied</Message></Error>`.
enum ServerErrorMessage {
    static func extract(from body: Data) -> String? {
        guard !body.isEmpty else { return nil }
        let reader = MessageReader()
        let parser = XMLParser(data: body)
        parser.delegate = reader
        parser.parse()
        let message = reader.message.trimmingCharacters(in: .whitespacesAndNewlines)
        return message.isEmpty ? nil : message
    }
}

private final class MessageReader: NSObject, XMLParserDelegate {
    private(set) var message = ""
    private var isInMessage = false

    func parser(
        _ parser: XMLParser, didStartElement elementName: String,
        namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]
    ) {
        isInMessage = elementName == "Message"
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isInMessage { message += string }
    }

    func parser(
        _ parser: XMLParser, didEndElement elementName: String,
        namespaceURI: String?, qualifiedName: String?
    ) {
        if elementName == "Message" { parser.abortParsing() }
        isInMessage = false
    }
}
