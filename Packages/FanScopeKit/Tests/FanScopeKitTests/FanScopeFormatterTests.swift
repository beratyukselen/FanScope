import Foundation
import Testing
@testable import FanScopeKit

@Suite("FanScopeFormatter")
struct FanScopeFormatterTests {
    @Test("Formats standard TRY prices with two decimal places")
    func standardTRYPrice() throws {
        let price = try #require(Decimal(string: "10.31"))
        #expect(FanScopeFormatter.tryPrice(price) == "10,31 ₺")
    }

    @Test("Formats sub-1 TRY prices with four decimal places")
    func subOneTRYPrice() throws {
        let price = try #require(Decimal(string: "0.4682"))
        #expect(FanScopeFormatter.tryPrice(price) == "0,4682 ₺")
    }

    @Test("Adds plus sign only for positive percentages")
    func signedPercentages() {
        #expect(FanScopeFormatter.signedPercentage(1.44) == "+1,44%")
        #expect(FanScopeFormatter.signedPercentage(-5.36) == "-5,36%")
        #expect(FanScopeFormatter.signedPercentage(0) == "0,00%")
    }

    @Test("Compacts million and billion token supplies")
    func compactTokenAmounts() {
        #expect(FanScopeFormatter.compactTokenAmount(41_296_676) == "41,3M")
        #expect(FanScopeFormatter.compactTokenAmount(10_621_699_378) == "10,62B")
        #expect(FanScopeFormatter.compactTokenAmount(7_699) == "7,7K")
        #expect(FanScopeFormatter.compactTokenAmount(250) == "250")
    }

    @Test("Shortens hex wallet addresses while preserving short inputs")
    func shortenedAddress() {
        let address = "0xc80Afd311c9626528De66D86814770361Fe92416"
        #expect(FanScopeFormatter.shortenedAddress(address) == "0xc80A...2416")
        #expect(FanScopeFormatter.shortenedAddress("0x1234") == "0x1234")
    }
}
