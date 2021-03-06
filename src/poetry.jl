
# Particularly useful or beautiful grammar of graphics invocations.

## Return a DataFrame with x, y column suitable for plotting a function.
#
# Args:
#  f: Function/Expression to be evaluated.
#  a: Lower bound.
#  b: Upper bound.
#  n: Number of points to evaluate the function at.
#
# Returns:
#  A data frame with "x" and "f(x)" columns.
#
function evalfunc(f::Function, a, b, n)
    xs = [x for x in a:(b - a)/n:b]
    df = DataFrame(xs, map(f, xs))
    # NOTE: 'colnames!' is the older deprecated name. 'names!' was also defined
    # but threw an error.
    try
        names!(df, [:x, symbol("f(x)")])
    catch
        colnames!(df, ["x", "f(x)"])
    end
    df
end


evalfunc(f::Expr, a, b, n) = evalfunc(eval(:(x -> $f)), a, b, n)


# Create a dataframe and mapping from a list of functions or expressions.
function datafy(fs::Array, a, b)
    df = DataFrame()
    name_levels = ASCIIString[]
    for (i, f) in enumerate(fs)
        df_i = evalfunc(f, a, b, 250)
        name = typeof(f) == Expr ? string(f) : @sprintf("f<sub>%d</sub>", i)
        try
            df_i[:f] = fill(name, size(df_i, 1))
        catch
            df_i["f"] = fill(name, size(df_i, 1))
        end
        push!(name_levels, name)
        df = vcat(df, df_i)
    end
    df[:f] = PooledDataArray(df[:f], name_levels)

    mapping = {:x => "x", :y => "f(x)"}
    if length(fs) > 1
        mapping[:color] = "f"
    end

    df, mapping
end


# A convenience plot function for quickly plotting functions or expressions.
#
# Args:
#   fs: An array in which each object is either a single argument function or an
#       expression computing some value on x.
#   a: Lower bound on x.
#   b: Upper bound on x.
#   elements: One ore more grammar elements.
#
# Returns:
#   A plot objects.
#
function plot(fs::Array, a, b, elements::ElementOrFunction...; mapping...)
    df, mappingdict = datafy(fs, a, b)
    for (k, v) in mapping
        mappingdict[k] = v
    end
    plot(df, mappingdict, Geom.line, elements...)
end

# Plot a single function.
function plot(f::Function, a, b, elements::ElementOrFunction...; mapping...)
    plot([f], a, b, elements...; mapping...)
end


# Plot a single expression.
function plot(f::Expr, a, b, elements::ElementOrFunction...; mapping...)
    plot([f], a, b, elements...; mapping...)
end


# Plot an expression from a to b.
macro plot(expr, a, b)
    quote
        plot(x -> $(expr), $(a), $(b))
    end
end


# Create a layer from a list of functions or expressions.
function layer(fs::Array, a, b)
    df, mapping = datafy(fs, a, b)
    layer(df, Stat.nil(), Geom.line; mapping...)
end


# Create a layer from a single function.
function layer(f::Function, a, b)
    layer([f], a, b)
end


# Create a layer from a single expression.
function layer(f::Expr, a, b)
    layer([f], a, b)
end


# Create a layer from an expression from a to b.
macro layer(expr, a, b)
    quote
        layer(x -> $(expr), $(a), $(b))
    end
end


# Simple heatmap plots of matrices.
#
# Args:
#   M: A matrix.
#
# Returns:
#   A plot object.
#
function spy(M::AbstractMatrix, elements::ElementOrFunction...; mapping...)
    is, js, values = findnz(M)
    df = DataFrame(i=is, j=js, value=values)
    plot(df, x="j", y="i", color="value",
         Coord.cartesian(yflip=true),
         Scale.continuous_color,
         Scale.x_discrete,
         Scale.y_discrete,
         Geom.rectbin,
         Stat.identity,
         elements...;
         mapping...)
end


