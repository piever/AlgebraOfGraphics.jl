struct MixedTuple{T<:Tuple, NT<:NamedTuple}
    args::T
    kwargs::NT
end

const Tup = Union{Tuple, NamedTuple, MixedTuple}

function mixedtuple(args...; kwargs...)
    nt = values(kwargs)
    MixedTuple(args, nt)
end

Base.iterate(m::MixedTuple) = Base.iterate((m.args..., m.kwargs...))
Base.iterate(m::MixedTuple, i) = Base.iterate((m.args..., m.kwargs...), i)
Base.length(m::MixedTuple) = length(m.args) + length(m.kwargs)

function Base.eltype(::Type{MixedTuple{T, NT}}) where {T, NT}
    Base.promote_typejoin(eltype(T), eltype(NT))
end

function Base.map(f, m::MixedTuple, ms::MixedTuple...)
    args = map(t -> t.args, (m, ms...))
    kwargs = map(t -> t.kwargs, (m, ms...))
    return MixedTuple(map(f, args...), map(f, kwargs...))
end

function Base.show(io::IO, mt::MixedTuple)
    print(io, "MixedTuple")
    args, kwargs = mt.args, mt.kwargs
    print(io, "(")
    kwargs = values(kwargs)
    na, nk = length(args), length(kwargs)
    for i in 1:na
        show(io, args[i])
        if i < na + nk
            print(io, ", ")
        end
    end
    for i in 1:nk
        print(io, keys(kwargs)[i])
        print(io, " = ")
        show(io, kwargs[i])
        if i < nk
            print(io, ", ")
        end
    end
    print(io, ")")
end

function Base.merge(a::MixedTuple, b::MixedTuple)
    tup = (a.args..., b.args...)
    nt = merge(a.kwargs, b.kwargs)
    return MixedTuple(tup, nt)
end

function Base.:(==)(m1::MixedTuple, m2::MixedTuple)
    m1.args == m2.args && m1.kwargs == m2.kwargs
end
