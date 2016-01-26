
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
