@testable import PeatedCore
import Testing

/// Ports the web's bottle display-name cases so both surfaces title a bottle the same way.
struct BottleIdentityTests {
    private func bottle(
        name: String = "Glenburgie 38-year-old",
        groupName: String? = "Glenburgie 38-year-old",
        brand: Brand = Brand(id: "1", name: "Decadent Drinks"),
        series: String? = "Whiskyland",
        edition: String? = "Chapter Thirty Two",
        vintageYear: Int? = 1988,
        releaseYear: Int? = 2026,
        statedAge: Int? = nil,
        abv: Double? = nil,
        category: String? = nil,
        distillers: [Brand] = [],
        noAgeStatement: Bool? = nil
    ) -> Bottle {
        Bottle(
            id: "10",
            name: name,
            fullName: "\(brand.name) \(name)",
            brand: brand,
            category: category,
            edition: edition,
            series: series.map { BottleSeriesSummary(id: "s", name: $0) },
            groupName: groupName,
            statedAge: statedAge,
            vintageYear: vintageYear,
            releaseYear: releaseYear,
            noAgeStatement: noAgeStatement,
            distillers: distillers,
            abv: abv
        )
    }

    @Test
    func formatsOneConciseIdentityByDefault() {
        let name = BottleDisplayName.format(bottle())

        #expect(name == "Decadent Drinks Whiskyland Glenburgie 38-year-old - Chapter Thirty Two")
    }

    @Test
    func removesStoredFactsFromTheMarketedName() {
        let bottle = bottle(
            name: "Tun 89 Teaspooned Malt - 36-year-old - 2026 Release - 1989 Vintage - 52.4% ABV",
            groupName: nil,
            brand: Brand(id: "2", name: "Milroy's of Soho"),
            series: nil,
            edition: nil,
            vintageYear: 1989,
            releaseYear: 2026,
            statedAge: 36,
            abv: 52.4
        )

        #expect(BottleDisplayName.format(bottle) == "Milroy's of Soho Tun 89 Teaspooned Malt")
    }

    @Test
    func omitsBrandAndSeriesWhenTheLayoutShowsThem() {
        let withoutBrand = BottleDisplayName.format(bottle(), includeBrand: false)
        let withoutSeries = BottleDisplayName.format(bottle(), includeBrand: false, includeSeries: false)

        #expect(withoutBrand == "Whiskyland Glenburgie 38-year-old - Chapter Thirty Two")
        #expect(withoutSeries == "Glenburgie 38-year-old - Chapter Thirty Two")
    }

    @Test
    func keepsInferredYearsOutOfTheName() {
        #expect(BottleDisplayName.format(bottle(edition: nil)) == "Decadent Drinks Whiskyland Glenburgie 38-year-old")
    }

    @Test
    func keepsANumberedBatchBesideTheName() {
        let batched = bottle(edition: "Batch C923", vintageYear: nil)

        #expect(BottleDisplayName.format(batched) == "Decadent Drinks Whiskyland Glenburgie 38-year-old")
        #expect(BottleDisplayName.releaseMetadata(for: batched) == "Batch C923")
    }

    @Test(arguments: ["9.3", "S2B13"])
    func rendersCompactEditionCodesInline(edition: String) {
        let name = BottleDisplayName.format(bottle(edition: edition))

        #expect(name == "Decadent Drinks Whiskyland Glenburgie 38-year-old \(edition)")
    }

    @Test
    func keepsASeparatorBeforeAWordedEdition() {
        let name = BottleDisplayName.format(bottle(edition: "2026 Release"))

        #expect(name == "Decadent Drinks Whiskyland Glenburgie 38-year-old - 2026 Release")
    }

    @Test
    func usesTheBrandShortNameWhenSet() {
        let bottle = bottle(brand: Brand(id: "1", name: "Decadent Drinks Limited", shortName: "Decadent"))

        #expect(BottleDisplayName.format(bottle) == "Decadent Whiskyland Glenburgie 38-year-old - Chapter Thirty Two")
    }

    @Test
    func doesNotRepeatSeriesWording() {
        let bottle = bottle(
            name: "Exploration Series No. 1 - Chapter Thirty Two",
            groupName: nil,
            brand: Brand(id: "3", name: "Pōkeno"),
            series: "Exploration Series"
        )

        #expect(BottleDisplayName.format(bottle) == "Pōkeno Exploration Series No. 1 - Chapter Thirty Two")
    }

    @Test
    func returnsAtMostOneSupportingReleaseFact() {
        #expect(BottleDisplayName.releaseMetadata(for: bottle(edition: nil)) == "1988 vintage")
        #expect(BottleDisplayName.releaseMetadata(for: bottle()) == nil)
        #expect(BottleDisplayName.releaseMetadata(for: bottle(edition: nil, vintageYear: nil)) == "2026 release")
    }

    @Test
    func formatsCategoryNames() {
        #expect(BottleDisplayName.categoryName("single_malt") == "Single Malt")
        #expect(BottleDisplayName.categoryName("blend") == "Blended Whisky")
        #expect(BottleDisplayName.categoryName(nil) == nil)
    }

    @Test
    func buildsTheThreeIdentityLines() {
        let identity = BottleIdentity(bottle: bottle(
            name: "10-year-old",
            groupName: nil,
            brand: Brand(id: "1", name: "Ardbeg"),
            series: nil,
            edition: nil,
            vintageYear: nil,
            releaseYear: 2019,
            statedAge: 10,
            abv: 46,
            category: "single_malt",
            distillers: [Brand(id: "1", name: "Ardbeg"), Brand(id: "9", name: "Port Ellen")]
        ))

        #expect(identity.name == "Ardbeg 10-year-old")
        #expect(identity.provenance == ["Port Ellen", "Single Malt"])
        #expect(identity.metadata == ["2019 release", "10 years", "46.0% ABV"])
    }

    @Test
    func showsNoAgeStatementAndVintageFacts() {
        let identity = BottleIdentity(bottle: bottle(
            groupName: nil,
            edition: nil,
            vintageYear: 1988,
            releaseYear: 2026,
            noAgeStatement: true
        ))

        #expect(identity.metadata == ["1988 vintage", "2026 release", "NAS"])
    }

    @Test
    func collapsesManyDistilleries() {
        let distillers = (1 ... 4).map { Brand(id: "d\($0)", name: "Distillery \($0)") }
        let identity = BottleIdentity(bottle: bottle(distillers: distillers))

        #expect(identity.provenance == ["4 distilleries"])
    }
}
