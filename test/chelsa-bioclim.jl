@testset "CHELSEA BioClim" begin
    using RasterDataSources: rasterurl

    @test rastername(CHELSA{BioClim}, 5) == "CHELSA_bio10_05.tif"

    bioclim_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "CHELSA", "BioClim")
    @test rasterpath(CHELSA{BioClim}) == bioclim_path
    @test rasterpath(CHELSA{BioClim}, 5) == joinpath(bioclim_path, "CHELSA_bio10_05.tif")

    @test rasterurl(CHELSA) == 
        URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/chelsa_V1/")
    @test rasterurl(CHELSA{BioClim}, 5) == 
        URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/chelsa_V1/climatologies/bio/CHELSA_bio10_05.tif")

    getraster(CHELSA{BioClim}, 5)
    @test isfile(joinpath(bioclim_path, "CHELSA_bio10_05.tif"))
end
