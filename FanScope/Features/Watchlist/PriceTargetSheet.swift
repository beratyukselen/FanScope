import FanScopeKit
import SwiftUI

struct PriceTargetSheet: View {
    let fixedSymbol: String?
    let currentPriceTRY: Decimal?
    let existingEntry: WatchlistEntry?
    let onSave: (String, Decimal?, PriceTargetDirection, String, Bool) -> Void
    let onRemove: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSymbol: String
    @State private var targetPriceText: String
    @State private var direction: PriceTargetDirection
    @State private var noteText: String
    @State private var enableLocalAlert: Bool

    init(
        fixedSymbol: String? = nil,
        currentPriceTRY: Decimal? = nil,
        existingEntry: WatchlistEntry? = nil,
        onSave: @escaping (String, Decimal?, PriceTargetDirection, String, Bool) -> Void,
        onRemove: ((String) -> Void)? = nil
    ) {
        self.fixedSymbol = fixedSymbol
        self.currentPriceTRY = currentPriceTRY
        self.existingEntry = existingEntry
        self.onSave = onSave
        self.onRemove = onRemove

        let initialSymbol = fixedSymbol ?? existingEntry?.symbol ?? TokenCatalog.all.first?.symbol ?? "FB"
        self._selectedSymbol = State(initialValue: initialSymbol)
        self._targetPriceText = State(
            initialValue: existingEntry?.targetPriceTRY.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        )
        self._direction = State(initialValue: existingEntry?.targetDirection ?? .above)
        self._noteText = State(initialValue: existingEntry?.note ?? "")
        self._enableLocalAlert = State(initialValue: existingEntry?.targetPriceTRY != nil)
    }

    private var parsedTargetPrice: Decimal? {
        let normalized = targetPriceText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty, let value = Decimal(string: normalized), value > 0 else {
            return nil
        }
        return value
    }

    private var hasInvalidPriceInput: Bool {
        !targetPriceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedTargetPrice == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                if fixedSymbol == nil {
                    Section("watchlist.sheet.token_section") {
                        Picker("watchlist.sheet.token_picker", selection: $selectedSymbol) {
                            ForEach(TokenCatalog.all) { token in
                                Text("\(token.symbol) — \(token.name)")
                                    .tag(token.symbol)
                            }
                        }
                    }
                } else if let currentPriceTRY {
                    Section {
                        HStack {
                            Text("watchlist.sheet.current_price")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(FanScopeFormatter.tryPrice(currentPriceTRY))
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                    }
                }

                Section {
                    HStack {
                        TextField("watchlist.sheet.target_placeholder", text: $targetPriceText)
                            .keyboardType(.decimalPad)
                        Text("₺")
                            .foregroundStyle(.secondary)
                    }

                    Picker("watchlist.sheet.direction", selection: $direction) {
                        Text("watchlist.direction.above").tag(PriceTargetDirection.above)
                        Text("watchlist.direction.below").tag(PriceTargetDirection.below)
                    }
                    .pickerStyle(.segmented)

                    if parsedTargetPrice != nil {
                        Toggle("watchlist.sheet.enable_alert", isOn: $enableLocalAlert)
                    }
                } header: {
                    Text("watchlist.sheet.target_section")
                } footer: {
                    if hasInvalidPriceInput {
                        Text("watchlist.sheet.invalid_price")
                            .foregroundStyle(AppColors.negative)
                    } else {
                        Text("watchlist.sheet.target_footer")
                    }
                }

                Section("watchlist.sheet.note_section") {
                    TextField(
                        "watchlist.sheet.note_placeholder",
                        text: $noteText,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                }

                if existingEntry != nil, let onRemove {
                    Section {
                        Button(role: .destructive) {
                            onRemove(selectedSymbol)
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("watchlist.sheet.remove")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(
                existingEntry == nil
                    ? Text("watchlist.sheet.title_add")
                    : Text("watchlist.sheet.title_edit")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.save") {
                        HapticFeedback.lightImpact()
                        onSave(
                            selectedSymbol,
                            parsedTargetPrice,
                            direction,
                            noteText,
                            enableLocalAlert && parsedTargetPrice != nil
                        )
                        dismiss()
                    }
                    .disabled(hasInvalidPriceInput)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
