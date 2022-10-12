import CachedAsyncImage
import GoTrue
import SwiftUI

struct ProductCardView: View {
    let checkIn: CheckInResponse
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    if let avatarUrL = checkIn.profiles.avatar_url {
                        CachedAsyncImage(url: getAvatarURL(avatarUrl: avatarUrL)) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .clipShape(Circle())
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 30, height: 30)
                    }
                    Text(checkIn.profiles.username)
                        .font(.system(size: 12, weight: .bold, design: .default))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .cornerRadius(10)
                .padding(.trailing, 10)
                .padding(.leading, 10)
                .padding(.top, 10)

                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Spacer()

                        Text(checkIn.products.sub_brands.brands.name)
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .foregroundColor(.white)
                        if checkIn.products.sub_brands.name != "" {
                            Text(checkIn.products.sub_brands.name)
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .foregroundColor(.white)
                        }
                        Text(checkIn.products.name)
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .foregroundColor(.white)
                        Text(checkIn.products.sub_brands.brands.companies.name)
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundColor(.gray)

                        Spacer()
                        HStack {
                            RatingView(rating: checkIn.rating ?? 0)
                                .padding(.bottom, 10)
                        }
                    }
                    .padding(.all, 10)

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color(.darkGray))
                .cornerRadius(5)
                .padding(.leading, 5)
                .padding(.trailing, 5)

                HStack {
                    if let createdAt = checkIn.created_at {
                        Text(createdAt).font(.system(size: 12, weight: .medium, design: .default))
                    }
                    Spacer()
                    ReactionsView(checkInId: checkIn.id, checkInReactions: checkIn.check_in_reactions)

                }.padding(.trailing, 8).padding(.leading, 8).padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cornerRadius(10)
            }.background(Color(.tertiarySystemBackground)).cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 0)

        }.padding(.all, 10)
    }
}

struct ReactionsView: View {
    let checkInId: Int
    @State var checkInReactions: [CheckInReactionResponse]
    
    init(checkInId: Int, checkInReactions: [CheckInReactionResponse]) {
        _checkInReactions = State(initialValue: checkInReactions)
        self.checkInId = checkInId
    }
    
    var body: some View {
        HStack {
            ForEach(checkInReactions, id: \.id) {
                reaction in MiniAvatar(avatarUrl: reaction.profiles.avatar_url)
            }
            
            Button {
                if let existingReaction = checkInReactions.first(where: { $0.created_by == getCurrentUserIdUUID() }) {
                    removeReaction(reactionId: existingReaction.id)
                } else {
                    reactToCheckIn()
                }
            } label: {
                Text("\(checkInReactions.count)").font(.system(size: 14, weight: .bold, design: .default)).foregroundColor(.black)
                Image(systemName: "hand.thumbsup.fill").frame(alignment: .leading).foregroundColor(Color(.systemYellow))
            }
        }

    }
    
    func reactToCheckIn() {
        let query = API.supabase.database.from("check_in_reactions")
            .insert(values: CheckInReactionRequest(check_in_id: checkInId, created_by: getCurrentUserIdUUID()), returning: .representation)
            .select(columns: "id, created_by, profiles (id, username, avatar_url)")
            .limit(count: 1)
            .single()

        Task {
            let checkInReaction = try await query.execute().decoded(to: CheckInReactionResponse.self)
            DispatchQueue.main.async {
                self.checkInReactions.append(checkInReaction)
             }
        }
    }

    func removeReaction(reactionId: Int) {
        let query = API.supabase.database.from("check_in_reactions")
            .delete().eq(column: "id", value: reactionId)
        

        Task {
            try await query.execute()
            
            DispatchQueue.main.async {
                self.checkInReactions.removeAll(where: { $0.created_by == getCurrentUserIdUUID() })
            }
        }
    }
    
    struct CheckInReactionRequest: Encodable {
        let check_in_id: Int
        let created_by: UUID
    }
}

extension ProductCardView {
    @MainActor class ProductCardViewModel: ObservableObject {
        @Published var checkIn: CheckInResponse
        private var currentUserUUID: UUID

        struct CheckInReactionRequest: Encodable {
            let check_in_id: Int
            let created_by: UUID
        }

        init(checkIn: CheckInResponse) {
            self.checkIn = checkIn
            self.currentUserUUID = getCurrentUserIdUUID()
        }
    }
}
