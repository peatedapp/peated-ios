import Foundation
import PeatedAPI

// MARK: - User Mapping

extension User {
    init(from apiUser: Components.Schemas.User) {
        self.init(
            id: apiUser.id,
            email: apiUser.email,
            username: apiUser.username,
            verified: apiUser.verified,
            admin: apiUser.admin,
            mod: apiUser.mod
        )
        pictureUrl = apiUser.pictureUrl
    }

    init(from apiUser: Components.Schemas.Auth.userPayload) {
        self.init(
            id: apiUser.id,
            email: apiUser.email,
            username: apiUser.username,
            verified: apiUser.verified,
            admin: apiUser.admin,
            mod: apiUser.mod
        )
        pictureUrl = apiUser.pictureUrl
    }
}

// MARK: - Tasting Mapping

extension TastingFeedItem {
    static func from(_ apiTasting: Components.Schemas.Tasting) -> TastingFeedItem {
        let apiUser = apiTasting.createdBy
        let apiBottle = apiTasting.bottle

        // Extract all values first
        let id = String(Int(apiTasting.id))
        let rating = extractRating(from: apiTasting.rating)
        let notes = apiTasting.notes
        let servingStyle = apiTasting.servingStyle?.rawValue
        let imageUrl: String? = apiTasting.imageUrl
        let createdAt = apiTasting.createdAt
        let userId = String(Int(apiUser.id))
        let username = apiUser.username
        let userDisplayName: String? = nil
        let userAvatarUrl = apiUser.pictureUrl
        let bottleId = String(Int(apiBottle.id))
        let bottleName = apiBottle.fullName
        let bottleBrandName = apiBottle.brand.name
        let bottleCategory = apiBottle.category?.rawValue
        let bottleImageUrl: String? = apiBottle.imageUrl
        let toastCount = Int(apiTasting.toasts)
        let commentCount = Int(apiTasting.comments)
        let hasToasted = apiTasting.hasToasted ?? false
        let tags: [String] = apiTasting.tags ?? []
        let location: String? = nil
        let friendUsernames: [String] = apiTasting.friends?.map(\.username) ?? []

        return TastingFeedItem(
            id: id,
            rating: rating,
            notes: notes,
            servingStyle: servingStyle,
            imageUrl: imageUrl,
            createdAt: createdAt,
            userId: userId,
            username: username,
            userDisplayName: userDisplayName,
            userAvatarUrl: userAvatarUrl,
            bottleId: bottleId,
            bottleName: bottleName,
            bottleBrandName: bottleBrandName,
            bottleCategory: bottleCategory,
            bottleImageUrl: bottleImageUrl,
            toastCount: toastCount,
            commentCount: commentCount,
            hasToasted: hasToasted,
            tags: tags,
            location: location,
            friendUsernames: friendUsernames
        )
    }
}

// MARK: - Achievement Mapping

extension Achievement {
    init(from badgeResult: Components.Schemas.BadgeAward) {
        let badge = badgeResult.badge
        self.init(
            id: String(Int(badge.id)),
            name: badge.name,
            level: Int(badgeResult.level),
            imageUrl: badge.imageUrl,
            unlockedAt: nil
        )
    }
}

// MARK: - Bottle Mapping

extension Bottle {
    init(from apiBottle: Components.Schemas.Bottle) {
        let category = apiBottle.category?.rawValue
        let ratingStats = BottleRatingStats(
            pass: Int(apiBottle.ratingStats.pass),
            sip: Int(apiBottle.ratingStats.sip),
            savor: Int(apiBottle.ratingStats.savor),
            total: Int(apiBottle.ratingStats.total),
            average: apiBottle.ratingStats.avg,
            percentages: .init(
                pass: apiBottle.ratingStats.percentage.pass,
                sip: apiBottle.ratingStats.percentage.sip,
                savor: apiBottle.ratingStats.percentage.savor
            )
        )

        self.init(
            id: String(Int(apiBottle.id)),
            name: apiBottle.name,
            fullName: apiBottle.fullName,
            brand: Brand(
                id: String(Int(apiBottle.brand.id)),
                name: apiBottle.brand.name
            ),
            category: category,
            description: apiBottle.description,
            edition: apiBottle.edition,
            series: apiBottle.series.map {
                BottleSeriesSummary(id: String(Int($0.id)), name: $0.name)
            },
            caskStrength: apiBottle.caskStrength ?? false,
            singleCask: apiBottle.singleCask ?? false,
            statedAge: apiBottle.statedAge.map { Int($0) },
            vintageYear: apiBottle.vintageYear.map { Int($0) },
            releaseYear: apiBottle.releaseYear.map { Int($0) },
            caskType: apiBottle.caskType?.rawValue,
            caskSize: apiBottle.caskSize?.rawValue,
            caskFill: apiBottle.caskFill?.rawValue,
            distillers: apiBottle.distillers?.map {
                Brand(id: String(Int($0.id)), name: $0.name)
            } ?? [],
            bottler: apiBottle.bottler.map {
                Brand(id: String(Int($0.id)), name: $0.name)
            },
            tastingNotes: apiBottle.tastingNotes.map {
                BottleTastingNotes(nose: $0.nose, palate: $0.palate, finish: $0.finish)
            },
            suggestedTags: apiBottle.suggestedTags ?? [],
            imageUrl: apiBottle.imageUrl,
            abv: apiBottle.abv,
            avgRating: apiBottle.avgRating,
            ratingStats: ratingStats,
            totalRatings: ratingStats.total,
            totalTastings: Int(apiBottle.totalTastings),
            isFavorite: apiBottle.isFavorite,
            isLibrary: apiBottle.isLibrary,
            hasTasted: apiBottle.hasTasted
        )
    }

    init(from apiBottle: Components.Schemas.Tasting.bottlePayload) {
        let ratingStats = BottleRatingStats(
            pass: Int(apiBottle.ratingStats.pass),
            sip: Int(apiBottle.ratingStats.sip),
            savor: Int(apiBottle.ratingStats.savor),
            total: Int(apiBottle.ratingStats.total),
            average: apiBottle.ratingStats.avg,
            percentages: .init(
                pass: apiBottle.ratingStats.percentage.pass,
                sip: apiBottle.ratingStats.percentage.sip,
                savor: apiBottle.ratingStats.percentage.savor
            )
        )

        self.init(
            id: String(Int(apiBottle.id)),
            name: apiBottle.name,
            fullName: apiBottle.fullName,
            brand: Brand(id: String(Int(apiBottle.brand.id)), name: apiBottle.brand.name),
            category: apiBottle.category?.rawValue,
            description: apiBottle.description,
            edition: apiBottle.edition,
            series: apiBottle.series.map {
                BottleSeriesSummary(id: String(Int($0.id)), name: $0.name)
            },
            caskStrength: apiBottle.caskStrength ?? false,
            singleCask: apiBottle.singleCask ?? false,
            statedAge: apiBottle.statedAge.map { Int($0) },
            vintageYear: apiBottle.vintageYear.map { Int($0) },
            releaseYear: apiBottle.releaseYear.map { Int($0) },
            caskType: apiBottle.caskType?.rawValue,
            caskSize: apiBottle.caskSize?.rawValue,
            caskFill: apiBottle.caskFill?.rawValue,
            distillers: apiBottle.distillers?.map {
                Brand(id: String(Int($0.id)), name: $0.name)
            } ?? [],
            bottler: apiBottle.bottler.map {
                Brand(id: String(Int($0.id)), name: $0.name)
            },
            tastingNotes: apiBottle.tastingNotes.map {
                BottleTastingNotes(nose: $0.nose, palate: $0.palate, finish: $0.finish)
            },
            suggestedTags: apiBottle.suggestedTags ?? [],
            imageUrl: apiBottle.imageUrl,
            abv: apiBottle.abv,
            avgRating: apiBottle.avgRating,
            ratingStats: ratingStats,
            totalRatings: ratingStats.total,
            totalTastings: Int(apiBottle.totalTastings),
            isFavorite: apiBottle.isFavorite,
            isLibrary: apiBottle.isLibrary,
            hasTasted: apiBottle.hasTasted
        )
    }
}
