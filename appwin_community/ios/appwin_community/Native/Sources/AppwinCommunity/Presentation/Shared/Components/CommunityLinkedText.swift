import SwiftUI

/// Text of a post or comment with its web links styled and tappable.
///
/// Members paste bare urls (« https://… », « www.… »): `NSDataDetector` finds
/// them, and SwiftUI's `Text` opens a `.link` run through `openURL`, so the
/// host app keeps control of how a url opens. The rest of the text is drawn
/// as before.
enum CommunityLinkedText {
    private static let detector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue
    )

    static func attributed(_ text: String, linkColor: Color) -> AttributedString {
        var result = AttributedString(text)
        guard let detector, text.contains(where: { $0 == "." || $0 == ":" }) else { return result }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        for match in detector.matches(in: text, range: range) {
            guard let url = match.url,
                  // Web links only: an email address is not a link a member meant to share.
                  url.scheme == "http" || url.scheme == "https",
                  let stringRange = Range(match.range, in: text),
                  let lower = AttributedString.Index(stringRange.lowerBound, within: result),
                  let upper = AttributedString.Index(stringRange.upperBound, within: result)
            else { continue }
            result[lower..<upper].link = url
            result[lower..<upper].foregroundColor = linkColor
            result[lower..<upper].underlineStyle = .single
        }
        return result
    }
}
