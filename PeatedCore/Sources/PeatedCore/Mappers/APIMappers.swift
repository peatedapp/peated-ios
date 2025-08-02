import Foundation
import PeatedAPI

// MARK: - User Mapping

extension User {
  init(from apiUser: Operations.Auth_me.Output.Ok.Body.JsonPayload.UserPayload) {
    self.init(
      id: apiUser.id,
      email: apiUser.email,
      username: apiUser.username,
      verified: apiUser.verified,
      admin: apiUser.admin,
      mod: apiUser.mod
    )
  }
  
  init(from apiUser: Operations.Auth_login.Output.Ok.Body.JsonPayload.UserPayload) {
    self.init(
      id: apiUser.id,
      email: apiUser.email,
      username: apiUser.username,
      verified: apiUser.verified,
      admin: apiUser.admin,
      mod: apiUser.mod
    )
  }
}

// MARK: - Tasting Mapping

extension TastingFeedItem {
  static func from(_ apiTasting: Operations.Tastings_list.Output.Ok.Body.JsonPayload.ResultsPayloadPayload) -> TastingFeedItem {
    let apiUser = apiTasting.createdBy
    let apiBottle = apiTasting.bottle
    
    // Extract all values first
    let id = String(Int(apiTasting.id))
    let rating = apiTasting.rating ?? 0.0
    let notes = apiTasting.notes
    let servingStyle: String? = apiTasting.servingStyle?.value as? String
    let imageUrl: String? = apiTasting.imageUrl
    let createdAt = apiTasting.createdAt
    let userId = String(Int(apiUser.id))
    let username = apiUser.username
    let userDisplayName: String? = nil
    let userAvatarUrl = apiUser.pictureUrl
    let bottleId = String(Int(apiBottle.id))
    let bottleName = apiBottle.fullName
    let bottleBrandName = apiBottle.brand.name
    let bottleCategory: String? = apiBottle.category?.value as? String
    let bottleImageUrl: String? = apiBottle.imageUrl
    let toastCount = Int(apiTasting.toasts)
    let commentCount = Int(apiTasting.comments)
    let hasToasted = apiTasting.hasToasted ?? false
    let tags: [String] = apiTasting.tags ?? []
    let location: String? = nil
    let friendUsernames: [String] = apiTasting.friends?.map { $0.username } ?? []
    
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
  init(from badgeResult: Operations.Users_badgeList.Output.Ok.Body.JsonPayload.ResultsPayloadPayload) {
    let badge = badgeResult.badge
    self.init(
      id: String(Int(badge.id)),
      name: badge.name,
      level: Int(badgeResult.level),
      imageUrl: nil,
      unlockedAt: nil
    )
  }
}

// MARK: - Bottle Mapping

extension Bottle {
  init(from apiBottle: Operations.Bottles_details.Output.Ok.Body.JsonPayload) {
    let category: String? = apiBottle.category?.value as? String
    
    self.init(
      id: String(Int(apiBottle.id)),
      name: apiBottle.name,
      fullName: apiBottle.fullName,
      brand: Brand(
        id: String(Int(apiBottle.brand.id)),
        name: apiBottle.brand.name
      ),
      category: category,
      caskStrength: apiBottle.caskStrength ?? false,
      singleCask: apiBottle.singleCask ?? false,
      statedAge: apiBottle.statedAge.map { Int($0) }
    )
  }
}