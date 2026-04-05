

$ImportConfig = Get-Content .\Settings.config | ConvertFrom-Json



$ListOfCinemas = [pscustomobject]@{
        CName = "CinemaCity-MallOfSofia"; 
        CID = 1261;
        HomeAddress = 'https://www.cinemacity.bg/';
        LocationURI =  'https://www.cinemacity.bg/cinemas/mallofsofia/1261';
        DisplayName = 'Cinema City - Mall Of Sofia'
    },
    [pscustomobject]@{
        CName = "CinemaCity-ParadiseCenter"; 
        CID = 1266;
        HomeAddress = 'https://www.cinemacity.bg/';
        LocationURI = 'https://www.cinemacity.bg/cinemas/paradisecenter/1266';
        DisplayName = 'Cinema City - Paradice Center'
    },
    [pscustomobject]@{CName = "CineGrand"; HomeAddress = 'https://cinegrand.bg/'},
    [pscustomobject]@{CName = "KinoArena"; HomeAddress = 'https://www.kinoarena.com/'}



$MovieName = 'Проектът „Аве Мария“'

$SearchDate = (Get-Date).AddDays(1)

<#
# Source - https://stackoverflow.com/a/51774034
# Posted by Theo
# Retrieved 2026-04-05, License - CC BY-SA 4.0

$OpenSessionResponse = Invoke-WebRequest -Uri $ListOfCinemas[0].HomeAddress  -SessionVariable WebSession1 -Method Get
$Response = Invoke-WebRequest -Uri 'https://www.cinemacity.bg/cinemas/mallofsofia/1261#/buy-tickets-by-cinema?in-cinema=1261&at=2026-04-05&view-mode=list' -WebSession $WebSession1

# Source - https://stackoverflow.com/a/51774034
# Posted by Theo
# Retrieved 2026-04-05, License - CC BY-SA 4.0

$fileUploadPage = Invoke-WebRequest -Uri $fileUploadurl -WebSession $login


#>

####CinemaCity#####

#Rearch for showing:
$CinemaCityDate = $SearchDate.ToString("yyyy-MM-dd")

$MoviesListCinemaCity = @()

$report = foreach ($Cinema in $ListOfCinemas | where cname -like 'CinemaCity*'){

    $headers = @{
        "User-Agent" = "Mozilla/5.0"
        "Accept" = "application/json"
        "Referer" = $Cinema.LocationURI
    }

    $response = Invoke-RestMethod -Uri "www.cinemacity.bg/bg/data-api-service/v1/quickbook/10106/film-events/in-cinema/$($Cinema.CID)/at-date/$CinemaCityDate" -Headers $headers -Method Get

    $MoviesListCinemaCity += $response.body.films

    $response.body.events | select @{n='MovieName';e={$event = $_ ; ($Response.body.films | where id -like $event.filmid).name}},
        filmId,eventDateTime,auditorium,auditoriumTinyName,@{n='CinemaName';e={$Cinema.DisplayName}}

}

$index = 0
$MoviesListCinemaCityFormatted = $MoviesListCinemaCity | sort name -Unique | foreach {$index++ ;  $_ |select @{n='Index';e={$index}},Name,id,releaseDate,releaseYear,@{n='Length in minutes';e={$_.Length.ToString('# Min')}}}



Write-Host "$($MoviesListCinemaCityFormatted | ft -AutoSize | Out-String)"

Remove-Variable MovieByChoice,MovieIndexChoice
$MovieIndexChoice = Read-Host "Choose Movie name by specifying Index number"

$MovieByChoice = $MoviesListCinemaCityFormatted | where index -EQ $MovieIndexChoice

if(!$MovieByChoice){
    Write-Warning "Can't find movie with Index id - $MovieIndexChoice"
    break
}

$report | where MovieName -like ($MoviesListCinemaCityFormatted | where index -EQ $MovieIndexChoice).name | ft -AutoSize -GroupBy cinemaname

