import Foundation

struct BillDraft: Equatable {
    var title: String
    var cents: Int
    var personIDs: [UUID]
    var category: ExpenseCategory
    var isRecurring: Bool
}

enum BillParser {
    private static let stopWords: Set<String> = [
        "with", "and", "plus", "split", "between", "for", "a", "an", "the",
        "bill", "paid", "by", "from", "our", "my", "me", "i", "&", "to"
    ]

    static func parse(_ raw: String, people: [Person]) -> BillDraft {
        let you = people.first(where: \.isCurrentUser)
        var tokens = raw
            .replacingOccurrences(of: ",", with: "")
            .split(whereSeparator: { $0.isWhitespace || $0 == "/" })
            .map(String.init)
            .filter { !$0.isEmpty }

        var cents = 0
        var moneyIndex: Int?
        for (index, token) in tokens.enumerated().reversed() {
            if let value = parseMoney(token) {
                cents = value
                moneyIndex = index
                break
            }
        }
        if let moneyIndex {
            tokens.remove(at: moneyIndex)
        }

        var matched: [Person] = []
        var leftover: [String] = []
        for token in tokens {
            let key = normalize(token)
            if stopWords.contains(key) { continue }
            if key == "you" || key == "me" {
                if let you { matched.append(you) }
                continue
            }
            if let person = people.first(where: { matches($0, token: key) }) {
                if !matched.contains(where: { $0.id == person.id }) {
                    matched.append(person)
                }
                continue
            }
            leftover.append(token)
        }

        if let you, !matched.contains(where: { $0.id == you.id }) {
            matched.insert(you, at: 0)
        }

        let blob = raw.lowercased()
        let category = inferCategory(from: blob, leftover: leftover)
        let recurring = inferRecurring(from: blob, category: category)
        var title = leftover.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty {
            title = category.title
        } else {
            title = title.prefix(1).uppercased() + title.dropFirst()
        }

        return BillDraft(
            title: String(title.prefix(160)),
            cents: cents,
            personIDs: matched.map(\.id),
            category: category,
            isRecurring: recurring
        )
    }

    static func parseMoney(_ raw: String) -> Int? {
        var token = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if token.hasPrefix("$") { token.removeFirst() }
        token = token.replacingOccurrences(of: ",", with: "")
        guard !token.isEmpty, token.allSatisfy({ $0.isNumber || $0 == "." }) else { return nil }
        guard let decimal = Decimal(string: token), decimal > 0 else { return nil }
        return NSDecimalNumber(decimal: decimal * 100).intValue
    }

    private static func matches(_ person: Person, token: String) -> Bool {
        let names = [
            person.firstName,
            person.handle,
            person.displayName
        ].map(normalize)
        return names.contains(token)
    }

    private static func normalize(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private static func inferCategory(from blob: String, leftover: [String]) -> ExpenseCategory {
        let text = (blob + " " + leftover.joined(separator: " ")).lowercased()
        if text.contains("rent") || text.contains("lease") { return .rent }
        if text.contains("uber") || text.contains("lyft") || text.contains("ride") || text.contains("taxi") { return .ride }
        if text.contains("ticket") || text.contains("concert") || text.contains("show") { return .tickets }
        if text.contains("electric") || text.contains("power") || text.contains("utility") { return .electric }
        if text.contains("wifi") || text.contains("internet") || text.contains("broadband") { return .internet }
        if text.contains("groc") { return .groceries }
        if text.contains("dinner") || text.contains("lunch") || text.contains("brunch") || text.contains("food") { return .dinner }
        return .other
    }

    private static func inferRecurring(from blob: String, category: ExpenseCategory) -> Bool {
        if blob.contains("monthly") || blob.contains("every month") || blob.contains("each month") {
            return true
        }
        return category == .rent || category == .electric || category == .internet
    }
}

enum Recurrence: String, Codable, CaseIterable {
    case none
    case monthly

    static func nextDue(after date: Date = .now) -> Date {
        Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date
    }

    static func dueCopy(nextDueAt: Date?, isRecurring: Bool, settled: Bool, now: Date = .now) -> String? {
        guard !settled else { return nil }
        if isRecurring, let due = nextDueAt {
            let start = Calendar.current.startOfDay(for: now)
            let dueDay = Calendar.current.startOfDay(for: due)
            let days = Calendar.current.dateComponents([.day], from: start, to: dueDay).day ?? 0
            let when = due.formatted(date: .abbreviated, time: .omitted)
            if days < 0 {
                return "This month’s share is still open. Nobody is charged in the app."
            }
            if days == 0 {
                return "Due today. Settle outside when you’re ready."
            }
            if days <= 7 {
                return "Due in \(days) day\(days == 1 ? "" : "s"). Nobody is charged in the app."
            }
            return "Next due \(when). Monthly — we never auto-charge."
        }
        return "Settle when you can. Zeroed doesn’t take the money."
    }
}
