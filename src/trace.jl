struct MixedTuple{T<:Tuple, NT<:NamedTuple}
    args::T
    kwargs::NT
end

function mixedtuple(args...; kwargs...)
    nt = values(kwargs)
    MixedTuple(args, nt)
end

function Base.map(f, m::MixedTuple, ms::MixedTuple...)
    args = map(t -> t.args, (m, ms...))
    kwargs = map(t -> t.kwargs, (m, ms...))
    return MixedTuple(map(f, args...), map(f, kwargs...))
end

function Base.show(io::IO, m::MixedTuple)
    print(io, "MixedTuple")
    _show(io, m.args...; m.kwargs...)
end

function merge(a::MixedTuple, b::MixedTuple)
    tup = (a.args..., b.args...)
    nt = merge(a.kwargs, b.kwargs)
    return MixedTuple(tup, nt)
end

function Base.:(==)(m1::MixedTuple, m2::MixedTuple)
    m1.args == m2.args && m1.kwargs == m2.kwargs
end

abstract type AbstractTrace end

struct Trace{C, P<:MixedTuple, D<:MixedTuple, M<:MixedTuple} <: AbstractTrace
    context::C
    primary::P
    data::D
    metadata::M
end

const empty_trace = Trace(nothing, mixedtuple(), mixedtuple(), mixedtuple())

(t::Trace)(s::AbstractTrace) = merge(s, t)
(t::Trace)(s) = merge(data(s), t)

function Trace(
               t::AbstractTrace=empty_trace;
               context=nothing,
               primary=mixedtuple(),
               data=mixedtuple(),
               metadata=mixedtuple()
              )
    return merge(t, Trace(context, primary, data, metadata))
end

traces(t::AbstractTrace) = [t]

function merge(s1::Trace, s2::Trace)
    @assert s2.context === nothing || s2.context === s1.context
    context = s1.context
    primary = merge(s1.primary, s2.primary)
    data = merge(s1.data, s2.data)
    metadata = merge(s1.metadata, s2.metadata)
    return Trace(context, primary, data, metadata)
end

function Base.show(io::IO, s::Trace)
    print(io, "Trace with context")
    show(io, s.context)
    print(io, ", primary")
    show(io, s.primary)
    print(io, ", data")
    show(io, s.data)
    print(io, ", metadata")
    show(io, s.metadata)
end

context(x) = Trace(context = x)
context(s::Trace) = s.context
primary(args...; kwargs...) = Trace(primary = mixedtuple(args...; kwargs...))
primary(s::Trace) = s.primary
data(args...; kwargs...) = Trace(data = mixedtuple(args...; kwargs...))
data(s::Trace) = s.data
metadata(args...; kwargs...) = Trace(metadata = mixedtuple(args...; kwargs...))
metadata(s::Trace) = s.metadata

function _rename(t::Tuple, m::MixedTuple)
    mt = _rename(tail(t), m(tail(m.args), m.kwargs))
    MixedTuple((first(t), mt.args...), mt.kwargs)
end
function _rename(t::Tuple, m::MixedTuple{Tuple{}, <:NamedTuple{names}}) where names
    return MixedTuple((), NamedTuple{names}(t))
end

function to_vectors(vs...)
    i = findfirst(t -> isa(t, AbstractVector), vs)
    i === nothing && return nothing
    map(vs) do v
        v isa AbstractVector ? v : fill(v[], length(vs[i]))
    end
end

abstract type AbstractTraceList{T} end

struct TraceList{T} <: AbstractTraceList{T}
    traces::T
end
const null = TraceList(())
traces(t::TraceList) = t.traces

TraceList(l::TraceList) = l

Base.iterate(p::AbstractTraceList) = iterate(traces(p))
Base.iterate(p::AbstractTraceList, st) = iterate(traces(p), st)
Base.length(p::AbstractTraceList) = length(traces(p))
Base.axes(p::AbstractTraceList) = axes(traces(p))
Base.eltype(::Type{<:AbstractTraceList{T}}) where {T} = eltype(T)

Base.IteratorEltype(::Type{<:AbstractTraceList{T}}) where {T} = Base.IteratorEltype(T)
Base.IteratorSize(::Type{<:AbstractTraceList{T}}) where {T} = Base.IteratorSize(T)

function Base.show(io::IO, l::TraceList)
    print(io, "TraceList with traces ")
    show(io, traces(l))
end

+(a::AbstractTrace, b::AbstractTrace) = TraceList([a]) + TraceList([b])
+(a::AbstractTraceList, b::AbstractTrace) = a + TraceList([b])
+(a::AbstractTrace, b::AbstractTraceList) = TraceList([a]) + b
+(a::AbstractTraceList, b::AbstractTraceList) = TraceList(Iterators.flatten(traces.([a, b])))

function consistent(s::AbstractTrace, t::AbstractTrace)
    return consistent(primary(s).kwargs, primary(t).kwargs)
end

merge(s::AbstractTrace, t::AbstractTraceList) = merge(TraceList(traces(s)), t)
merge(s::AbstractTraceList, t::AbstractTrace) = merge(s, TraceList(traces(t)))
function merge(s::AbstractTraceList, t::AbstractTraceList)
    prod = Iterators.product(traces(s), traces(t))
    return TraceList(merge(els, elt) for (els, elt) in prod if consistent(els, elt))
end

function (l::TraceList)(v=nothing)
    # do not flatten, keep nested structure?
    ts = Iterators.flatten(traces(el(v)) for el in traces(l))
    return TraceList(ts)
end
