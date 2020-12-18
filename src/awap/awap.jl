"""
    AWAP <: RasterDataSource

Daily weather data from the Australian Water Availability Project, developed by CSIRO.

See: [www.csiro.au/awap](http://www.csiro.au/awap/)
"""
struct AWAP <: RasterDataSource end

const AWAP_PATHSEGMENTS = (
    solar = ("solar", "solarave", "daily"),
    rainfall = ("rainfall", "totals", "daily"),
    vprpress09 = ("vprp", "vprph09", "daily"),
    vprpress15 = ("vprp", "vprph15", "daily"),
    tmin = ("temperature", "minave", "daily"),
    tmax = ("temperature", "maxave", "daily"),
)
# Add ndvi monthly?  ndvi, ndviave, month

layers(::Type{AWAP}) = (:solar, :rainfall, :vprpress09, :vprpress15, :tmin, :tmax)

"""
    getraster(T::Type{AWAP}, layer::Symbol; date) => Vector{String}

Download data from the AWAP weather dataset, for `layer` in $(layers(AWAP)),
and `date` as a `DateTime` or iterable of `DateTime`.

AWAP is available on a daily timestep. If no `layer` is specified, 
all layers will be getrastered, and a `Tuple` of `Vector{String}` will be returned.

## Example

Rainfall for the first month of 2001
```julia
getraster(AWAP, :rainfall; date=Date(2001, 1, 1):Day(1):Date(2001, 1, 31))
```
"""
function getraster(T::Type{AWAP}, layer::Symbol; date)
    _check_layer(T, layer)
    dates = _date_sequence(date, Day(1))
    mkpath(_rasterpath(T, layer))
    raster_paths = String[]
    for d in dates
        raster_path = rasterpath(T, layer; date=d)
        if !isfile(raster_path)
            zip_path = zippath(T, layer; date=d)
            _maybe_download(zipurl(T, layer; date=d), zip_path)
            run(`uncompress $zip_path -f`)
        end
        push!(raster_paths, raster_path)
    end
    return raster_paths
end

rasterpath(T::Type{AWAP}) = joinpath(rasterpath(), "AWAP")
rasterpath(T::Type{AWAP}, layer; date::Dates.AbstractTime) =
    joinpath(_rasterpath(T, layer), rastername(T, layer; date))
_rasterpath(T::Type{AWAP}, layer) = joinpath(rasterpath(T), AWAP_PATHSEGMENTS[layer][1:2]...)
rastername(T::Type{AWAP}, layer; date::Dates.AbstractTime) =
    joinpath(_date2string(T, date) * ".grid")

function zipurl(T::Type{AWAP}, layer; date)
    s = AWAP_PATHSEGMENTS[layer]
    d = _date2string(T, date)
    # The actual zip name has the date twice, which is weird.
    # So we getraster in to a different name as there no output
    # name flages for `uncompress`. It's ancient.
    uri = URI(scheme="http", host="www.bom.gov.au", path="/web03/ncc/www/awap")
    joinpath(uri, s..., "grid/0.05/history/nat/$d$d.grid.Z")
end
zipname(T::Type{AWAP}, layer; date) = _date2string(T, date) * ".grid.Z"
zippath(T::Type{AWAP}, layer; date) = 
    joinpath(_rasterpath(T, layer), zipname(T, layer; date))


_dateformat(::Type{AWAP}) = DateFormat("yyyymmdd")
