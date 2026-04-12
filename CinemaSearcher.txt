
$finalReport = @()

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
    [pscustomobject]@{
        CName = "CineGrand-ParkCenter"; 
        CID = 0;
        HomeAddress = 'https://cinegrand.bg/';
        LocationURI = 'https://cinegrand.bg/%D0%BF%D0%B0%D1%80%D0%BA-%D1%86%D0%B5%D0%BD%D1%82%D1%8A%D1%80-%D1%81%D0%BE%D1%84%D0%B8%D1%8F/schedule';
        DisplayName = 'Cine Grand - Park Center'
    },
        [pscustomobject]@{
        CName = "CineGrand-SofiaRingMall"; 
        CID = 0;
        HomeAddress = 'https://cinegrand.bg/';
        LocationURI = 'https://cinegrand.bg/%D1%81%D0%BE%D1%84%D0%B8%D1%8F-%D1%80%D0%B8%D0%BD%D0%B3-%D0%BC%D0%BE%D0%BB/schedule';
        DisplayName = 'Cinema City - Sofia Ring Mall'
    },
    [pscustomobject]@{CName = "KinoArena"; HomeAddress = 'https://www.kinoarena.com/'}



#$MovieName = 'Проектът „Аве Мария“'

$Today = (Get-Date)
$ListOfDates = @()
$ListOfDates += $Today
$ListOfDates += 1..7 | foreach {(Get-date).AddDays($_)}

$Thursday = $ListOfDates | where DayOfWeek -like "Thursday"

$RangeOfDates = $ListOfDates | where {$_ -ge $Today -and $_ -le $Thursday}

$index1 = 0
$RangeOfDatesFormatted = $RangeOfDates | foreach {$index1++ ;  $_ | select @{n='Index';e={$index1}},DayOfWeek,@{n='DateF';e={$_.ToShortDateString()}},Date}

Write-Host "$($RangeOfDatesFormatted | ft Index,DayOfWeek,DateF -AutoSize | Out-String)"

Remove-Variable MovieByChoice,MovieIndexChoice -ErrorAction SilentlyContinue
$DateIndexChoice = Read-Host "Choose date by specifying Index number"

$SearchDate = $RangeOfDatesFormatted | where index -EQ $DateIndexChoice

if(!$SearchDate){
    Write-Warning "Can't find movies for that date id - $DateIndexChoice"
    break
}

Write-Host "Date chosen: $($SearchDate | ft Index,DayOfWeek,DateF -AutoSize -HideTableHeaders | Out-String)"

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
$CinemaCityDate = $SearchDate.Date.ToString("yyyy-MM-dd")

$MoviesListCinemaCity = @()

$report = foreach ($Cinema in $ListOfCinemas | where cname -like 'CinemaCity*'){

    $headers = @{
        "User-Agent" = "Mozilla/5.0"
        "Accept" = "application/json"
        "Referer" = $Cinema.LocationURI
    }

    $response = Invoke-RestMethod -Uri "www.cinemacity.bg/bg/data-api-service/v1/quickbook/10106/film-events/in-cinema/$($Cinema.CID)/at-date/$CinemaCityDate" -Headers $headers -Method Get

    $MoviesListCinemaCity = $($MoviesListCinemaCity;$response.body.films) | sort name -Unique

    $response.body.events | select @{n='MovieName';e={$event = $_ ; ($Response.body.films | where id -like $event.filmid).name}},
        filmId,eventDateTime,auditorium,auditoriumTinyName,@{n='CinemaName';e={$Cinema.DisplayName}}

}


#$report | where MovieName -like ($MoviesListCinemaCityFormatted | where index -EQ $MovieIndexChoice).name | ft -AutoSize -GroupBy cinemaname
$finalReport += $report


####Cinegrand#####

<#$DatesTranslateHash = @{
    Monday = 'понеделник'
    Tuesday = 'вторник'
    Wednesday = 'сряда'
    Thursday = 'четвъртък'
    Friday = 'петък'
    Saturday = 'събота'
    Sunday = 'неделя'
}
#>

#Rearch for showing:
$CineGrandDate = "$($SearchDate.Date.ToString("dddd"))-$($SearchDate.date.DayOfWeek.value__)"

$CineGrandDateURI = [uri]::EscapeDataString($CineGrandDate)


#$MoviesListCinemaCity = @()

$report2 = foreach ($Cinema in $ListOfCinemas | where cname -like 'CineGrand*'){
    $uri = "$($Cinema.LocationURI)-$CineGrandDateURI"

    $request = Invoke-WebRequest -Uri $uri -UseBasicParsing
    $HTML = New-Object -Com "HTMLFile"
    [string]$htmlBody = $request.Content
    $HTML.write([ref]$htmlBody)
    $filter = $HTML.getElementsByClassName("btn btn-sm btn-outline-dark show-time fs no-outline valid ")

    $CineGrandOutput = foreach ($HtmlResult in $filter){
        [pscustomobject]@{
            MovieName = ($HtmlResult.ie8_attributes | where {$_.nodename -like 'data-movie'}).Value
            eventDateTime = ($HtmlResult.ie8_attributes | where {$_.nodename -like 'data-run'}).Value | Get-Date
            auditorium = ($HtmlResult.ie8_attributes | where {$_.nodename -like 'title'}).Value.split(',')[-1].trim()
            #auditoriumTinyName = ($HtmlResult.ie8_attributes | where {$_.nodename -like 'title'}).Value.split(',')[-1].trim()
            CinemaName = $Cinema.DisplayName
        }
    }


    $CineGrandOutput | select MovieName,filmId,eventDateTime,auditorium,auditoriumTinyName,CinemaName

}



$finalReport += $report2



$index2 = 0
$MoviesListFormatted = $finalReport | sort MovieName -Unique | foreach {$index2++ ;  $_ | select @{n='Index';e={$index2}},MovieName}



Write-Host "$($MoviesListFormatted | ft -AutoSize | Out-String)"

Remove-Variable MovieByChoice,MovieIndexChoice -ErrorAction SilentlyContinue
$MovieFilter = Read-Host "Enter part of the movie name to filter the output, leave empty for no filter"

if($MovieFilter){
    $FilteredMovies = $finalReport | where moviename -Like "*$MovieFilter*"
}
else{$FilteredMovies = $finalReport}


if(!$FilteredMovies){
    Write-Warning "No movie found that contains '$moviefilter' in its name."  
    break  
}


$outputFormat = @(
    @{n='Movie Name'; e={$_.moviename}},
    @{n='Date'; e={$_.eventDateTime.ToShortDateString()}},
    @{n='Day'; e={$_.eventDateTime.DayOfWeek}},
    @{n='Time'; e={$_.eventDateTime.ToShortTimeString()}},
    @{n='Screen'; e={if($_.auditoriumTinyName){$_.auditoriumTinyName} else{$_.auditorium}}},
    @{n='Cinema Name'; e={$_.CinemaName}}
)

$FilteredMovies | select $outputFormat | ft -AutoSize


