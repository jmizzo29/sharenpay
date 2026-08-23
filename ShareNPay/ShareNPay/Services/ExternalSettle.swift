import Foundation
import SwiftUI
import UIKit

enum ExternalSettle {
    static func venmoURL(handle: String, cents: Int, note: String) -> URL? {
        guard !handle.isEmpty else { return nil }
        var components = URLComponents(string: "venmo://paycharge")
        components?.queryItems = [
            URLQueryItem(name: "txn", value: "pay"),
            URLQueryItem(name: "recipients", value: handle.replacingOccurrences(of: "@", with: "")),
            URLQueryItem(name: "amount", value: amountString(cents)),
            URLQueryItem(name: "note", value: note)
        ]
        return components?.url
    }

    static func cashAppURL(cashTag: String, cents: Int) -> URL? {
        guard !cashTag.isEmpty else { return nil }
        let tag = cashTag.hasPrefix("$") ? String(cashTag.dropFirst()) : cashTag
        return URL(string: "https://cash.app/$\(tag)/\(amountString(cents))")
    }

    /// Outbound paypal.me send-money link only. Not Checkout, Braintree, or any ShareNPay rail.
    static func paypalURL(handle: String, cents: Int) -> URL? {
        guard !handle.isEmpty else { return nil }
        var slug = handle
            .replacingOccurrences(of: "@", with: "")
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        if let range = slug.range(of: "paypal.me/", options: .caseInsensitive) {
            slug = String(slug[range.upperBound...])
        }
        if let range = slug.range(of: "paypal.com/paypalme/", options: .caseInsensitive) {
            slug = String(slug[range.upperBound...])
        }
        slug = slug.split(separator: "/").first.map(String.init) ?? slug
        guard !slug.isEmpty else { return nil }
        return URL(string: "https://www.paypal.com/paypalme/\(slug)/\(amountString(cents))")
    }

    static func zelleURL() -> URL? {
        URL(string: "https://www.zellepay.com/")
    }

    static func note(bill: String, cents: Int) -> String {
        "ShareNPay · \(bill) · \(LedgerMath.currencyString(cents: cents))"
    }

    static func amountString(_ cents: Int) -> String {
        String(format: "%.2f", Double(cents) / 100)
    }
}

struct SettleOutsideSheet: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    let payee: Person
    let cents: Int
    let billNote: String
    let onMarkPaid: () -> Void

    @State private var copied = false

    var body: some View {
        VStack(spacing: 28) {
            Capsule()
                .fill(SNP.hairline)
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            VStack(spacing: 6) {
                Text("Pay \(payee.firstName)")
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
                MoneyLabel(cents: cents, size: 44)
                Text(note)
                    .font(.caption)
                    .foregroundStyle(SNP.textMuted)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                if ExternalSettle.venmoURL(handle: payee.venmoHandle, cents: cents, note: note) != nil {
                    provider("Venmo") {
                        if let url = ExternalSettle.venmoURL(handle: payee.venmoHandle, cents: cents, note: note) {
                            openURL(url)
                        }
                    }
                }
                if ExternalSettle.cashAppURL(cashTag: payee.cashTag, cents: cents) != nil {
                    provider("Cash App") {
                        if let url = ExternalSettle.cashAppURL(cashTag: payee.cashTag, cents: cents) {
                            openURL(url)
                        }
                    }
                }
                if ExternalSettle.paypalURL(handle: payee.paypalHandle, cents: cents) != nil {
                    provider("PayPal") {
                        if let url = ExternalSettle.paypalURL(handle: payee.paypalHandle, cents: cents) {
                            openURL(url)
                        }
                    }
                }
                provider(copied ? "Copied" : "Zelle") {
                    UIPasteboard.general.string = "\(note) — \(payee.zelleHint.isEmpty ? payee.displayName : payee.zelleHint)"
                    copied = true
                    if let url = ExternalSettle.zelleURL() {
                        openURL(url)
                    }
                }
            }

            VStack(spacing: 10) {
                Button("Mark paid") {
                    onMarkPaid()
                    dismiss()
                }
                .buttonStyle(QuietButtonStyle(filled: true))
                Text("ShareNPay never takes this money.")
                    .font(.caption)
                    .foregroundStyle(SNP.textMuted)
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
        .presentationDetents([.height(390)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.regularMaterial)
    }

    private var note: String {
        ExternalSettle.note(bill: billNote, cents: cents)
    }

    private func provider(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(SNP.text)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(SNP.hairline, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
