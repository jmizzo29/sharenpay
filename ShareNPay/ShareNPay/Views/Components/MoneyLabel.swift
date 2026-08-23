import SwiftUI

struct MoneyLabel: View {
    let cents: Int
    var signed: Bool = false
    var emphasize: Bool = true
    var size: CGFloat = 28
    var tint: Color? = nil

    var body: some View {
        Text(LedgerMath.currencyString(cents: cents, signed: signed))
            .font(SNP.money(size, weight: emphasize ? .semibold : .medium))
            .monospacedDigit()
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .accessibilityLabel(accessibility)
    }

    private var color: Color {
        if let tint { return tint }
        return SNP.text
    }

    private var accessibility: String {
        if signed, cents > 0 { return "plus \(LedgerMath.currencyString(cents: cents))" }
        if signed, cents < 0 { return "minus \(LedgerMath.currencyString(cents: cents))" }
        return LedgerMath.currencyString(cents: cents)
    }
}

struct AmountField: View {
    @Binding var cents: Int
    var size: CGFloat = 36

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("$")
                .font(SNP.money(size * 0.58, weight: .medium))
                .foregroundStyle(SNP.textMuted)
            TextField("0.00", text: displayBinding)
                .keyboardType(.decimalPad)
                .font(SNP.money(size))
                .monospacedDigit()
                .foregroundStyle(SNP.text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Amount")
    }

    private var displayBinding: Binding<String> {
        Binding(
            get: {
                if cents == 0 { return "" }
                let dollars = cents / 100
                let remainder = cents % 100
                if remainder == 0 { return "\(dollars)" }
                return String(format: "%d.%02d", dollars, remainder)
            },
            set: { newValue in
                cents = Self.parse(newValue)
            }
        )
    }

    static func parse(_ raw: String) -> Int {
        let filtered = raw.filter { $0.isNumber || $0 == "." }
        guard !filtered.isEmpty else { return 0 }
        if let decimal = Decimal(string: filtered) {
            let cents = decimal * 100
            return NSDecimalNumber(decimal: cents).intValue
        }
        return 0
    }
}
