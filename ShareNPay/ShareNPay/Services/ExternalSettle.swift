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

    static func zelleURL() -> URL? {
        URL(string: "https://www.zellepay.com/")
    }

    static func note(household: String, bill: String, cents: Int) -> String {
        "\(household) · \(bill) · \(LedgerMath.currencyString(cents: cents))"
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
    let household: String
    let onMarkPaid: () -> Void

    @State private var copied = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Pay \(payee.firstName) \(LedgerMath.currencyString(cents: cents))")
                        .font(.headline)
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(SNP.textMuted)
                } footer: {
                    Text("ShareNPay never takes this money. Open Venmo, Cash App, or Zelle, then mark it paid here.")
                }
                Section("Pay outside") {
                    if let url = ExternalSettle.venmoURL(handle: payee.venmoHandle, cents: cents, note: note) {
                        Button("Open Venmo") { openURL(url) }
                    }
                    if let url = ExternalSettle.cashAppURL(cashTag: payee.cashTag, cents: cents) {
                        Button("Open Cash App") { openURL(url) }
                    }
                    Button(copied ? "Copied for Zelle" : "Copy note for Zelle") {
                        UIPasteboard.general.string = "\(note) — \(payee.zelleHint.isEmpty ? payee.displayName : payee.zelleHint)"
                        copied = true
                        if let url = ExternalSettle.zelleURL() {
                            openURL(url)
                        }
                    }
                }
                Section {
                    Button("Mark paid") {
                        onMarkPaid()
                        dismiss()
                    }
                    .font(.headline)
                } footer: {
                    Text("Use after you send it outside the app.")
                }
            }
            .navigationTitle("Settle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var note: String {
        ExternalSettle.note(household: household, bill: billNote, cents: cents)
    }
}
