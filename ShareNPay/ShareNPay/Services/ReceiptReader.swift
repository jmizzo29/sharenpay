import Foundation
import UIKit
import Vision

enum ReceiptReader {
    struct Result: Equatable {
        var merchant: String
        var cents: Int
    }

    static func extract(from image: UIImage) async -> Result? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        return extract(fromLines: lines)
    }

    static func extract(fromLines lines: [String]) -> Result? {
        let joined = lines.joined(separator: "\n")
        let amounts = amounts(in: joined)
        guard let cents = pickTotal(from: lines, amounts: amounts) else { return nil }
        let merchant = pickMerchant(from: lines) ?? "Receipt"
        return Result(merchant: merchant, cents: cents)
    }

    static func amounts(in text: String) -> [Int] {
        let pattern = #"\$?\d{1,3}(?:,\d{3})*(?:\.\d{2})|\d+\.\d{2}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let slice = Range(match.range, in: text) else { return nil }
            return BillParser.parseMoney(String(text[slice]))
        }
    }

    private static func pickTotal(from lines: [String], amounts: [Int]) -> Int? {
        let labels = ["total", "amount due", "balance due", "grand total", "amount"]
        for line in lines.reversed() {
            let lower = line.lowercased()
            if labels.contains(where: { lower.contains($0) }), let cents = amounts(in: line).last {
                return cents
            }
        }
        return amounts.filter { $0 >= 100 && $0 <= 2_000_000 }.max() ?? amounts.max()
    }

    private static func pickMerchant(from lines: [String]) -> String? {
        let skip = ["total", "subtotal", "tax", "tip", "change", "cash", "card", "visa", "thank", "receipt", "auth"]
        for line in lines.prefix(8) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let letters = trimmed.filter(\.isLetter)
            guard letters.count >= 3, trimmed.count <= 40 else { continue }
            let lower = trimmed.lowercased()
            if skip.contains(where: { lower.contains($0) }) { continue }
            if BillParser.parseMoney(trimmed) != nil { continue }
            return trimmed
        }
        return nil
    }
}
