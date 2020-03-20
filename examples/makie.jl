using AbstractPlotting, GLMakie
using Observables
using AbstractPlotting: SceneLike, PlotFunc
using StatsMakie: linear, density

using AlgebraOfGraphics, Test
using AlgebraOfGraphics: TraceList,
                         TraceOrList,
                         data,
                         metadata,
                         primary,
                         mixedtuple,
                         rankdicts,
                         traces

using RDatasets: dataset

function AbstractPlotting.plot!(scn::SceneLike, P::PlotFunc, attr:: Attributes, s::TraceOrList)
    return AbstractPlotting.plot!(scn, P, attr, TraceList(traces(s)))
end

isabstractplot(s) = isa(s, Type) && s <: AbstractPlot

function AbstractPlotting.plot!(scn::SceneLike, P::PlotFunc, attributes::Attributes, ts::TraceList)
    palette = AbstractPlotting.current_default_theme()[:palette]
    rks = rankdicts(ts)
    for trace in ts
        key, val, m = primary(trace), data(trace), metadata(trace)
        P1 = foldl((a, b) -> isabstractplot(b) ? b : a, m.args, init=P)
        args = Iterators.filter(!isabstractplot, m.args)
        series_attr = merge(attributes, Attributes(m.kwargs))
        attrs = get_attrs(key.kwargs, series_attr, palette, rks)
        AbstractPlotting.plot!(scn, P1, merge(attrs, Attributes(val.kwargs)), args..., val.args...)
    end
    return scn
end

function get_attrs(grp::NamedTuple{names}, user_options, palette, rks) where names
    tup = map(names) do key
        user = get(user_options, key, Observable(nothing))
        default = get(palette, key, Observable(nothing))
        scale = isa(user[], AbstractVector) ? user[] : default[]
        val = getproperty(grp, key)
        idx = rks[key][val]
        scale isa AbstractVector ? scale[mod1(idx, length(scale))] : idx
    end
    return merge(user_options, Attributes(NamedTuple{names}(tup)))
end

#######

iris = dataset("datasets", "iris")
spec = iris |> data(:SepalLength, :SepalWidth) * primary(color = :Species)
s = metadata(Scatter, markersize = 10px) + metadata(linear)
plot(s * spec)

plt = metadata(Wireframe, density) * spec |> plot
scatter!(plt, spec)

df = iris
x = data(:PetalLength) * primary(marker = fill(1)) +
    data(:PetalWidth) * primary(marker = fill(2))
y = data(:SepalLength, color = :SepalWidth)
df |> metadata(Scatter) * x * y |> plot

x = [-pi..0, 0..pi]
y = [sin, cos]
ts1 = sum(((i, el),) -> primary(color = i) * data(el), enumerate(x))
ts2 = sum(((i, el),) -> primary(linestyle = i) * data(el), enumerate(y))
plot(ts1 * ts2 * metadata(linewidth = 10))
