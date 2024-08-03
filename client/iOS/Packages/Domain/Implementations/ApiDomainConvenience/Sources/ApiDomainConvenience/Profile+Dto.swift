import Domain
import DataTransferObjects

extension Profile {
    public init(dto: ProfileDto) {
        self = Profile(user: User(dto: dto.user), email: dto.email, isEmailVerified: dto.emailVerified)
    }
}

extension ProfileDto {
    public init(domain profile: Profile) {
        self = ProfileDto(user: UserDto(domain: profile.user), email: profile.email, emailVerified: profile.isEmailVerified)
    }
}
