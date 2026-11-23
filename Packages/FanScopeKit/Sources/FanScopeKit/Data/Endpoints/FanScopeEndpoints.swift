import Foundation

public enum FanScopeEndpoints {
    public enum Paribu {
        private static let host = "api.paribu.com"

        public static func marketTicker() -> Endpoint {
            Endpoint(host: host, path: "/market/ticker")
        }

        public static func orderBook(market: String) -> Endpoint {
            Endpoint(
                host: host,
                path: "/orderbook",
                queryItems: [URLQueryItem(name: "market", value: market.lowercased())]
            )
        }
    }

    public enum CoinGecko {
        private static let host = "api.coingecko.com"

        public static func markets(ids: [String]) -> Endpoint {
            Endpoint(
                host: host,
                path: "/api/v3/coins/markets",
                queryItems: [
                    URLQueryItem(name: "vs_currency", value: "try"),
                    URLQueryItem(name: "ids", value: ids.joined(separator: ",")),
                    URLQueryItem(name: "sparkline", value: "true"),
                ]
            )
        }
    }

    public enum Blockscout {
        private static let host = "eth.blockscout.com"

        public static func tokenInfo(contract: String) -> Endpoint {
            Endpoint(host: host, path: "/api/v2/tokens/\(contract)")
        }

        public static func tokenTransfers(contract: String) -> Endpoint {
            Endpoint(host: host, path: "/api/v2/tokens/\(contract)/transfers")
        }

        public static func tokenHolders(contract: String) -> Endpoint {
            Endpoint(host: host, path: "/api/v2/tokens/\(contract)/holders")
        }
    }

    public enum Routescan {
        private static let host = "api.routescan.io"
        private static let chilizChainID = "88888"

        public static func tokenSupply(contract: String) -> Endpoint {
            Endpoint(
                host: host,
                path: "/v2/network/mainnet/evm/\(chilizChainID)/etherscan/api",
                queryItems: [
                    URLQueryItem(name: "module", value: "stats"),
                    URLQueryItem(name: "action", value: "tokensupply"),
                    URLQueryItem(name: "contractaddress", value: contract),
                ]
            )
        }

        public static func tokenHolders(contract: String, limit: Int = 10) -> Endpoint {
            Endpoint(
                host: host,
                path: "/v2/network/mainnet/evm/\(chilizChainID)/erc20/\(contract)/holders",
                queryItems: [URLQueryItem(name: "limit", value: String(limit))]
            )
        }

        public static func addressTokenTransfers(
            contract: String,
            address: String,
            limit: Int = 25
        ) -> Endpoint {
            Endpoint(
                host: host,
                path: "/v2/network/mainnet/evm/\(chilizChainID)/etherscan/api",
                queryItems: [
                    URLQueryItem(name: "module", value: "account"),
                    URLQueryItem(name: "action", value: "tokentx"),
                    URLQueryItem(name: "contractaddress", value: contract),
                    URLQueryItem(name: "address", value: address),
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "offset", value: String(limit)),
                    URLQueryItem(name: "sort", value: "desc"),
                ]
            )
        }
    }
}
