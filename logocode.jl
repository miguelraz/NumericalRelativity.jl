
#!/usr/bin/env julia
#All credit to Cornmullion [over here on his git](https://gist.github.com/cormullion/b1f609ba53388d5bc03682d8d8eed48b)


using Luxor, Colors

"make a color more white"
function whiten(col::Color, f=0.5)
    hsl = convert(HSL, col)
    h, s, l = hsl.h, hsl.s, hsl.l
    return convert(RGB, HSL(h, f, f))
end

"make a grid of boxes (aka 'spacetime')"
function buildspacetime()
    squares = Tiler(600, 600, 25, 25)
    squarecoords = Array{Point, 1}[]
    for (sq, n) in squares
        push!(squarecoords, box(sq, squares.tilewidth, squares.tileheight, vertices=true))
    end
    return squarecoords
end

"""
    warpspacetime(aspacetime, starcenters; gravity=-2500)
move each point depending on its distance from each of the 'bodies' in `starcenters`
`gravity` is an arbitrary number used to move points depending on the square of their
distance (thanks Isaac N.)
"""
function warpspacetime(aspacetime, starcenters; gravity=-2500)
    newspacetime = Array{Point, 1}[]
    for eachbox in aspacetime
        newbox = Point[]
        for corner in eachbox
            # vectors of this corner to each of the stars
            # (mis)using Luxor.points as vectors
            vectors = [corner - p for p in starcenters]
            # get distances of this corner from the stars
            distances = norm.([corner], starcenters)
            # find attraction of this corner to the stars
            #= there's some arithmetic weirdness going on here, which I haven't investigated,
            but for now clamping it to some high number such as 7000 stops it
            =#
            gravities = [gravity * (v/(max(7000, d^2))) for (v, d) in zip(vectors, distances)]
            # find new corner
            newcorner = corner + sum(gravities)
            # store new corner
            push!(newbox, newcorner)
        end
        push!(newspacetime, newbox)
    end
    return newspacetime
end

function render()
    darker_purple    = (0.584, 0.345, 0.698)
    lighter_purple   = (0.667, 0.475, 0.757)
    darker_green     = (0.22, 0.596, 0.149)
    lighter_green    = (0.376, 0.678, 0.318)
    darker_red       = (0.796, 0.235, 0.2)
    lighter_red      = (0.835, 0.388, 0.361)
    color_sequence   = [(darker_red, lighter_red),
                        (darker_green, lighter_green),
                        (darker_purple, lighter_purple)]
    # build spacetime and stars
    spacetime = buildspacetime()
    numberofstars = 3
    # the 30 is an optical correction
    starcenters = ngon(Point(O.x, O.y + 30), 120, numberofstars, pi/6, vertices=true)
    # warp that spacetime with some arbitrary gravity
    warpedspacetime = warpspacetime(spacetime, starcenters, gravity=-2350)
    # start drawing
    setline(0.5)
    sethue("black")
    squircle(O, 240, 240, :fill)
    # start clipping
    squircle(O, 240, 240, :clip)
    # draw some small stars
    sethue("white")
    circle.(randompointarray(Point(-250, -250), Point(250, 250), 500), .5, :fill)
    # draw the fabric
    for b in warpedspacetime
        poly(b, close=true, :stroke)
    end
    # draw the stars (julia colored circles)
    ballradius = 30
    for (n, centerp) in enumerate(starcenters)
        gsave()
        translate(centerp)
        ccyc = mod1(n, length(color_sequence))
        c = Colors.RGB(color_sequence[ccyc][1]...)
        for i in ballradius:-1:1
            sethue(whiten(c, rescale(i, ballradius, 3, 0.3, 1.0)))
            circle(O, i, :fill)
        end
        grestore()
    end
    clipreset()
end

function main()
    Drawing(500, 500, "/tmp/warp.png")
    fontsize(6)
    origin()
    render()
    finish()
    preview()
end

main()
view rawwarp.jl hosted with ❤ by GitHub
