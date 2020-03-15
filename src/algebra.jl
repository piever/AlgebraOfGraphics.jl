abstract type AbstractElement end

abstract type AbstractComposite <: AbstractElement end

struct Product{T<:Tuple} <: AbstractComposite
    elements::T
    Product(args...) = new{typeof(args)}(args)
end
Product(l::Product) = l

function Base.show(io::IO, l::Product)
    print(io, "Product")
    _show(io, l.elements...)
end

*(a::AbstractElement, b::AbstractElement) = Product(a) * Product(b)
*(a::Product, b::Product) = append(a, b)

combine(a, b) = merge(a, b)

function get(p::Product, T::Type, init = T())
    vals = p.elements
    foldl(combine, Iterators.filter(x -> isa(x, T), vals), init=init)
end

struct Sum{T<:Tuple} <: AbstractComposite
    elements::T
    Sum(args...) = new{typeof(args)}(args)
end
Sum(l::Sum) = l

function Base.show(io::IO, l::Sum)
    print(io, "Sum")
    _show(io, l.elements...)
end

*(t::Sum, b::AbstractElement) = Sum(map(el -> el * b, t.elements)...)
*(a::AbstractElement, t::Sum) = Sum(map(el -> a * el, t.elements)...)
function *(s::Sum, t::Sum)
    f = (s * first(t.elements))
    ls = (s * Sum(tail(t.elements)...))
    return f + ls
end
*(s::Sum, ::Sum{Tuple{}}) = Sum()

+(a::AbstractElement, b::AbstractElement) = Sum(a) + Sum(b)
+(a::Sum, b::Sum) = Sum(a.elements..., b.elements...)