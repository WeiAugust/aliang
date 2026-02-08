import Foundation

enum PostTimestampFormatter {
    static func relativeText(
        for date: Date,
        relativeTo referenceDate: Date = Date(),
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        if abs(referenceDate.timeIntervalSince(date)) < 60 {
            return localizedJustNow(for: locale)
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = locale
        return formatter.localizedString(for: date, relativeTo: referenceDate)
    }

    private static func localizedJustNow(for locale: Locale) -> String {
        let localeIdentifier = locale.identifier.lowercased()
        if localeIdentifier.hasPrefix("zh") {
            return "刚刚"
        }
        return "just now"
    }
}
