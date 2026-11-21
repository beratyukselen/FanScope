import Foundation

public enum TokenCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case turkishClub
    case europeanClub
    case nationalTeam
    case ecosystem
}

public struct RGBColor: Hashable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public struct ClubColorPalette: Hashable, Sendable {
    public let primary: RGBColor
    public let secondary: RGBColor

    public init(primary: RGBColor, secondary: RGBColor) {
        self.primary = primary
        self.secondary = secondary
    }
}

public struct TokenDefinition: Identifiable, Hashable, Sendable {
    public let id: String
    public let symbol: String
    public let name: String
    public let paribuMarket: String
    public let category: TokenCategory
    public let network: BlockchainNetwork
    public let contractAddress: String
    public let decimals: Int
    public let coinGeckoID: String?
    public let badgeColors: ClubColorPalette

    public init(
        symbol: String,
        name: String,
        paribuMarket: String,
        category: TokenCategory,
        network: BlockchainNetwork,
        contractAddress: String,
        decimals: Int,
        coinGeckoID: String?,
        badgeColors: ClubColorPalette
    ) {
        self.id = symbol.lowercased()
        self.symbol = symbol
        self.name = name
        self.paribuMarket = paribuMarket
        self.category = category
        self.network = network
        self.contractAddress = contractAddress
        self.decimals = decimals
        self.coinGeckoID = coinGeckoID
        self.badgeColors = badgeColors
    }
}

public enum WalletRole: String, Hashable, Sendable {
    case nullAddress
    case exchangeHot
    case exchangeCold
    case treasury
}

public struct KnownWallet: Hashable, Sendable {
    public let address: String
    public let label: String
    public let role: WalletRole

    public init(address: String, label: String, role: WalletRole) {
        self.address = address.lowercased()
        self.label = label
        self.role = role
    }
}

public enum KnownWalletRegistry {
    public static let nullAddress = "0x0000000000000000000000000000000000000000"

    private static let wallets: [String: KnownWallet] = {
        let items: [KnownWallet] = [
            KnownWallet(address: nullAddress, label: "Null Address", role: .nullAddress),
            KnownWallet(
                address: "0xc80Afd311c9626528De66D86814770361Fe92416",
                label: "Paribu Hot Wallet",
                role: .exchangeHot
            ),
            KnownWallet(
                address: "0x76eC5A0D3632b2133d9f1980903305B62678Fbd3",
                label: "Paribu Cold Reserve 1",
                role: .exchangeCold
            ),
            KnownWallet(
                address: "0xc3681709ee476308b45812EAbE0EB22F3b816880",
                label: "Paribu Cold Reserve 2",
                role: .exchangeCold
            ),
            KnownWallet(
                address: "0x4879675Da42274a69F15f1cF969B2Cc6a455B7f9",
                label: "FB Treasury Vault",
                role: .treasury
            ),
            KnownWallet(
                address: "0xB383e9a85c13367C18D49dc4D6075E4e65E277A2",
                label: "FB Reserve Vault",
                role: .treasury
            ),
        ]
        return Dictionary(uniqueKeysWithValues: items.map { ($0.address, $0) })
    }()

    public static let primaryExchangeHotWallet = "0xc80Afd311c9626528De66D86814770361Fe92416"

    public static func wallet(for address: String) -> KnownWallet? {
        wallets[address.lowercased()]
    }
}

public enum TokenCatalog {
    public static let all: [TokenDefinition] = [
        // Turkish Clubs
        TokenDefinition(
            symbol: "FB",
            name: "Fenerbahce Token",
            paribuMarket: "fb_tl",
            category: .turkishClub,
            network: .ethereum,
            contractAddress: "0xFB19075D77a0F111796FB259819830F4780f1429",
            decimals: 6,
            coinGeckoID: nil,
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.96, green: 0.78, blue: 0.08),
                secondary: RGBColor(red: 0.05, green: 0.16, blue: 0.44)
            )
        ),
        TokenDefinition(
            symbol: "GAL",
            name: "Galatasaray Fan Token",
            paribuMarket: "gal_tl",
            category: .turkishClub,
            network: .chiliz,
            contractAddress: "0x770da1e5ddb22f3ccc2482493bd9b10a7a8a38ae",
            decimals: 18,
            coinGeckoID: "galatasaray-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.68, green: 0.07, blue: 0.14),
                secondary: RGBColor(red: 0.95, green: 0.65, blue: 0.06)
            )
        ),
        TokenDefinition(
            symbol: "BJK",
            name: "Besiktas Token",
            paribuMarket: "bjk_tl",
            category: .turkishClub,
            network: .ethereum,
            contractAddress: "0x1903BE033d3e436dd79a8Cf9030675BCf97aB589",
            decimals: 6,
            coinGeckoID: nil,
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.12, green: 0.12, blue: 0.14),
                secondary: RGBColor(red: 0.36, green: 0.36, blue: 0.40)
            )
        ),
        TokenDefinition(
            symbol: "TRA",
            name: "Trabzonspor Fan Token",
            paribuMarket: "tra_tl",
            category: .turkishClub,
            network: .chiliz,
            contractAddress: "0xeff432433dd57adfa37004af00db148f9407e7bd",
            decimals: 18,
            coinGeckoID: "trabzonspor-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.49, green: 0.07, blue: 0.20),
                secondary: RGBColor(red: 0.17, green: 0.56, blue: 0.84)
            )
        ),
        TokenDefinition(
            symbol: "GOZ",
            name: "Goztepe Fan Token",
            paribuMarket: "goz_tl",
            category: .turkishClub,
            network: .chiliz,
            contractAddress: "0x6ba1fb0dadaeb34ea24eb31d416805abe8921448",
            decimals: 18,
            coinGeckoID: "goztepe-s-k-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.85, green: 0.12, blue: 0.16),
                secondary: RGBColor(red: 0.96, green: 0.76, blue: 0.08)
            )
        ),

        // Ecosystem
        TokenDefinition(
            symbol: "CHZ",
            name: "Chiliz",
            paribuMarket: "chz_tl",
            category: .ecosystem,
            network: .ethereum,
            contractAddress: "0x3506424f91fd33084466f402d5d97f05f8e3b4af",
            decimals: 18,
            coinGeckoID: "chiliz",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.81, green: 0.05, blue: 0.24),
                secondary: RGBColor(red: 0.52, green: 0.04, blue: 0.18)
            )
        ),

        // European Clubs
        TokenDefinition(
            symbol: "BAR",
            name: "FC Barcelona Fan Token",
            paribuMarket: "bar_tl",
            category: .europeanClub,
            network: .chiliz,
            contractAddress: "0x1589248b4b61ed472cc21ca1f2114d93ab6910d5",
            decimals: 18,
            coinGeckoID: "fc-barcelona-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.00, green: 0.30, blue: 0.60),
                secondary: RGBColor(red: 0.65, green: 0.00, blue: 0.27)
            )
        ),
        TokenDefinition(
            symbol: "PSG",
            name: "Paris Saint-Germain",
            paribuMarket: "psg_tl",
            category: .europeanClub,
            network: .chiliz,
            contractAddress: "0xfe1d4a935df7a4a52f835f6104c97af9d72217f2",
            decimals: 18,
            coinGeckoID: "paris-saint-germain-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.00, green: 0.25, blue: 0.44),
                secondary: RGBColor(red: 0.85, green: 0.16, blue: 0.21)
            )
        ),
        TokenDefinition(
            symbol: "JUV",
            name: "Juventus Fan Token",
            paribuMarket: "juv_tl",
            category: .europeanClub,
            network: .chiliz,
            contractAddress: "0xeaf368dadc22524def47e8a1c26bfc17ac16e6f5",
            decimals: 18,
            coinGeckoID: "juventus-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.14, green: 0.14, blue: 0.16),
                secondary: RGBColor(red: 0.44, green: 0.44, blue: 0.48)
            )
        ),
        TokenDefinition(
            symbol: "ACM",
            name: "AC Milan Fan Token",
            paribuMarket: "acm_tl",
            category: .europeanClub,
            network: .chiliz,
            contractAddress: "0x062f6004fd0bf204d272ff115e5b84f7a01489d1",
            decimals: 18,
            coinGeckoID: "ac-milan-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.78, green: 0.08, blue: 0.12),
                secondary: RGBColor(red: 0.12, green: 0.12, blue: 0.14)
            )
        ),
        TokenDefinition(
            symbol: "ASR",
            name: "AS Roma Fan Token",
            paribuMarket: "asr_tl",
            category: .europeanClub,
            network: .chiliz,
            contractAddress: "0x0ac7bf9783ca1dcd86a39b5a2607160d29256eb0",
            decimals: 18,
            coinGeckoID: "as-roma-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.56, green: 0.08, blue: 0.16),
                secondary: RGBColor(red: 0.94, green: 0.68, blue: 0.12)
            )
        ),
        TokenDefinition(
            symbol: "ATM",
            name: "Atletico Madrid",
            paribuMarket: "atm_tl",
            category: .europeanClub,
            network: .chiliz,
            contractAddress: "0x7da0eb973d982ffca095e80437f5e37459a95c67",
            decimals: 18,
            coinGeckoID: "atletico-madrid",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.80, green: 0.13, blue: 0.18),
                secondary: RGBColor(red: 0.11, green: 0.22, blue: 0.46)
            )
        ),
        TokenDefinition(
            symbol: "CITY",
            name: "Manchester City",
            paribuMarket: "city_tl",
            category: .europeanClub,
            network: .chiliz,
            contractAddress: "0x7bd6242d775faef1d50b2aa18c2fbf329bddf295",
            decimals: 18,
            coinGeckoID: "manchester-city-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.42, green: 0.67, blue: 0.87),
                secondary: RGBColor(red: 0.11, green: 0.18, blue: 0.36)
            )
        ),
        TokenDefinition(
            symbol: "AFC",
            name: "Arsenal Fan Token",
            paribuMarket: "afc_tl",
            category: .europeanClub,
            network: .chiliz,
            contractAddress: "0x76088f3ed5dc655de9295d93868ec1eec654a615",
            decimals: 18,
            coinGeckoID: "arsenal-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.86, green: 0.07, blue: 0.13),
                secondary: RGBColor(red: 0.07, green: 0.16, blue: 0.34)
            )
        ),
        TokenDefinition(
            symbol: "INTER",
            name: "Inter Milan Fan Token",
            paribuMarket: "inter_tl",
            category: .europeanClub,
            network: .chiliz,
            contractAddress: "0x1b3385a26214057bb7e27c173ee2d14201752e73",
            decimals: 18,
            coinGeckoID: "inter-milan-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.00, green: 0.35, blue: 0.72),
                secondary: RGBColor(red: 0.10, green: 0.10, blue: 0.14)
            )
        ),
        TokenDefinition(
            symbol: "NAP",
            name: "Napoli Fan Token",
            paribuMarket: "nap_tl",
            category: .europeanClub,
            network: .chiliz,
            contractAddress: "0x90593e9602b38a0d5b63d9f34ac3560798cee7d4",
            decimals: 18,
            coinGeckoID: "napoli-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.05, green: 0.56, blue: 0.84),
                secondary: RGBColor(red: 0.04, green: 0.34, blue: 0.62)
            )
        ),

        // National Teams
        TokenDefinition(
            symbol: "ARG",
            name: "Argentina Fan Token",
            paribuMarket: "arg_tl",
            category: .nationalTeam,
            network: .chiliz,
            contractAddress: "0x4394886b1eec08fe88681462914702dc99d97eb7",
            decimals: 18,
            coinGeckoID: "argentine-football-association-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.36, green: 0.68, blue: 0.90),
                secondary: RGBColor(red: 0.18, green: 0.44, blue: 0.72)
            )
        ),
        TokenDefinition(
            symbol: "POR",
            name: "Portugal Fan Token",
            paribuMarket: "por_tl",
            category: .nationalTeam,
            network: .chiliz,
            contractAddress: "0x013f2407c6ef765f1199f8818b805121f269f5b8",
            decimals: 18,
            coinGeckoID: "portugal-national-team-fan-token",
            badgeColors: ClubColorPalette(
                primary: RGBColor(red: 0.76, green: 0.08, blue: 0.14),
                secondary: RGBColor(red: 0.04, green: 0.44, blue: 0.24)
            )
        ),
    ]

    private static let byMarketIndex: [String: TokenDefinition] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.paribuMarket.lowercased(), $0) }
    )

    private static let bySymbolIndex: [String: TokenDefinition] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.symbol.uppercased(), $0) }
    )

    public static func token(forParibuMarket market: String) -> TokenDefinition? {
        byMarketIndex[market.lowercased()]
    }

    public static func token(forSymbol symbol: String) -> TokenDefinition? {
        bySymbolIndex[symbol.uppercased()]
    }

    public static var coinGeckoIDs: [String] {
        all.compactMap(\.coinGeckoID)
    }
}
