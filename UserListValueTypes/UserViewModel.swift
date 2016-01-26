//
//  Created by Christopher Trott on 1/14/16.
//  Copyright © 2016 twocentstudios. All rights reserved.
//

import Foundation

struct Lens<Whole, Part> {
    let get: Whole -> Part
    let set: (Part, Whole) -> Whole
}

func compose<A, B, C>(lhs: Lens<A, B>, rhs: Lens<B, C>) -> Lens<A, C> {
    return Lens<A, C>(
        get: { rhs.get(lhs.get($0)) },
        set: { (c, a) -> A in
            lhs.set(rhs.set(c, lhs.get(a)), a)
        }
    )
}

func * <A, B, C>(lhs: Lens<A, B>, rhs: Lens<B, C>) -> Lens<A, C> {
    return compose(lhs, rhs: rhs)
}

infix operator *~ { associativity left precedence 100 }
func *~ <A, B>(lhs: Lens<A, B>, rhs: B) -> A -> A {
    return { a in lhs.set(rhs, a) }
}

infix operator |> { associativity left precedence 80 }
func |> <A, B>(x: A, f: A -> B) -> B {
    return f(x)
}

func |> <A, B, C>(f: A -> B, g: B -> C) -> A -> C {
    return { g(f($0)) }
}

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
}
