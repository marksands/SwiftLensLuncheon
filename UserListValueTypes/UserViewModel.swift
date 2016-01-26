//
//  Created by Christopher Trott on 1/14/16.
//  Copyright © 2016 twocentstudios. All rights reserved.
//

import Foundation

/// UserViewModel is a value type that contains the static data prepared for consumption by the view layer.
/// The avatarImageData field represents an external image resource in various states (empty, loading, loaded, errored).
/// As a value-type, in order to change states, a completely new UserViewModel must be created.
struct UserViewModel {
    
    /// The underlying model object that this view model represents.
    /// This attribute is considered invisible to the View layer of the application.
    let user: User
    
    let name: String
    let avatarImageData: AsyncResource<NSURL, NSData>
    
    /// Convenience initializer for creating a view model from a User model and no other data.
    init(user: User) {
        self.init(user: user, avatarImageData: AsyncResource(input: user.avatarURL, output: AsyncResourceState.Empty))
    }
    
    /// Designated initalizer.
    init(user: User, avatarImageData: AsyncResource<NSURL, NSData>) {
        self.user = user
        self.name = user.name
        self.avatarImageData = avatarImageData
    }
    
    func shouldFetchAvatarImage() -> Bool {
        return avatarImageData.shouldFetch()
    }
}

/// We consider UserViewModels to be of equal identity if their underlying User models are the equal.
extension UserViewModel: Identifiable {}
func =~=(lhs: UserViewModel, rhs: UserViewModel) -> Bool {
    return lhs.user == rhs.user
}

extension UserViewModel {
    static let imageLoadingLens = Lens<UserViewModel, Float>(
        get: {
            guard case .Loading(let progress) = $0.avatarImageData.output else { fatalError() }
            return progress
        },
        set: { (progress, userViewModel) in
            let resource = userViewModel.avatarImageData.withOutput(.Loading(progress))
            return UserViewModel(user: userViewModel.user, avatarImageData: resource)
        }
    )

    static let imageDataLens = Lens<UserViewModel, NSData>(
        get: {
            guard case .Loaded(let data) = $0.avatarImageData.output else { fatalError() }
            return data
        },
        set: { (data, userViewModel) in
            let resource = userViewModel.avatarImageData.withOutput(.Loaded(data))
            return UserViewModel(user: userViewModel.user, avatarImageData: resource)
        }
    )

    static let imageErrorLens = Lens<UserViewModel, ErrorType>(
        get: {
            guard case .Error(let error) = $0.avatarImageData.output else { fatalError() }
            return error
        },
        set: { (error, userViewModel) in
            let resource = userViewModel.avatarImageData.withOutput(.Error(error))
            return UserViewModel(user: userViewModel.user, avatarImageData: resource)
        }
    )

    static let asyncResourceLens = Lens<UserViewModel, AsyncResource<NSURL, NSData>>(
        get: { $0.avatarImageData },
        set: { (asyncResource, userViewModel) -> UserViewModel in
            return UserViewModel(user: userViewModel.user, avatarImageData: asyncResource)
        }
    )
}

extension AsyncResource where InputType: NSURL, OutputType: NSData {
    static func inputLens() -> Lens<AsyncResource<NSURL, NSData>, NSURL> {
        return Lens<AsyncResource<NSURL, NSData>, NSURL>(
            get: { $0.input },
            set: { (inputType, resource) in
                AsyncResource<NSURL, NSData>(input: inputType, output: resource.output)
            }
        )
    }

    static func outputLens() -> Lens<AsyncResource<NSURL, NSData>, AsyncResourceState<NSData>> {
        return Lens<AsyncResource<NSURL, NSData>, AsyncResourceState<NSData>>(
            get: { $0.output },
            set: { (resourceOutputState, resource) in
                AsyncResource<NSURL, NSData>(input: resource.input, output: resourceOutputState)
            }
        )
    }
}
