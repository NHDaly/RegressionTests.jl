function transformation(x::SyntaxNode, rng=Random.default_rng())
    kind(x) === K"macrocall" || return nothing
    name = x.children[1]
    kind(name) === K"MacroName" || return nothing
    name.val === Symbol("@b_AUTO") || return nothing
    args = x.data.raw.args
    global XXX = x
    endpos = x.data.position + x.data.raw.span - 1
    prefix, insertion_point = if head(x).flags === 0x0000
        lst = last(args)
        whitespace = kind(lst) === K"Whitespace" ? lst.span : 0
        " ", endpos + 1 - whitespace:endpos
    elseif head(x).flags === 0x0020
        kind(last(args)) === K")" || error("expected )")
        whitespace = kind(args[end-1]) === K"Whitespace"
        last_non_whitespace = args[end-1-whitespace]
        k = kind(last_non_whitespace)
        prefix = k === K"(" ? "" : k === K"," ? " " : ", "
        prefix, endpos - (whitespace ? args[end-1].span : 0) : endpos - 1
    else
        error("unknown flag")
    end
    name.data.position:Int(name.data.position + name.data.raw.span - 1)=>"b", insertion_point=>(prefix * repr(rand(rng, UInt64)))
end

function write_transformed(io::IO, string::String, replacements)
    rs = sort!(collect(replacements), by=x->x[1].start)::AbstractVector{<:Pair{<:UnitRange, <:AbstractString}}
    print(io, string[1:first(first(rs)[1])-1])
    for ((s1, r2), (s2, _)) in zip(rs, Iterators.drop(rs, 1))
        print(io, r2)
        last(s1) < first(s2) || error("overlapping replacements, $(s1) and $(s2)")
        print(io, string[last(s1)+1:first(s2)-1])
    end
    print(io, rs[end][2])
    print(io, string[last(rs[end][1])+1:end])
end

function transformations(str::String; rng, kw...)
    res = Vector{Pair{UnitRange{Int}, String}}()
    for x in walktree(parseall(SyntaxNode, str; kw...))
        t = transformation(x, rng)
        t === nothing || push!(res, t...)
    end
    res
end

function transform_file(path::String; rng=Random.default_rng(), kw...)
    open(path, read=true, write=true) do io
        str = read(io, String)
        seekstart(io)
        trans = transformations(str; rng, filename=basename(path), kw...)
        write_transformed(io, str, trans)
    end
end
