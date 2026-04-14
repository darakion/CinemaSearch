

param($Request, $TriggerMetadata)

# Your existing logic starts here


##Modules:
    Import-Module PSParseHTML


## Functions:
function Get-CinemaCity {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory, ValueFromPipeline)]
        $SearchDate
        
    )
    
    begin {
        
    }
    
    process {

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

        return $report
        
    }
    
    end {
        
    }
}

function Get-CineGrand {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory, ValueFromPipeline)]
        $SearchDate
        
    )
    
    begin {
        
    }
    
    process {

        ####Cinegrand#####

        #Search for showing:
        $CineGrandDate = "$($SearchDate.Date.ToString("dddd"))-$($SearchDate.date.DayOfWeek.value__)"

        $CineGrandDateURI = [uri]::EscapeDataString($CineGrandDate)


        #$MoviesListCinemaCity = @()

        $report = foreach ($Cinema in $ListOfCinemas | where cname -like 'CineGrand*'){
            $uri = "$($Cinema.LocationURI)-$CineGrandDateURI"

            $request = Invoke-WebRequest -Uri $uri -UseBasicParsing


            $Parser = New-Object AngleSharp.Html.Parser.HtmlParser
            $Parsed = $Parser.ParseDocument($Request.Content)

            $ListOfMovies = $Parsed.All | where classname -like "btn btn-sm btn-outline-dark show-time fs no-outline valid "

            #$HTML = New-Object -Com "HTMLFile"
            #[string]$htmlBody = $request.Content
            #$HTML.write([ref]$htmlBody)
            #$filter = $HTML.getElementsByClassName("btn btn-sm btn-outline-dark show-time fs no-outline valid ")

            $CineGrandOutput = foreach ($HtmlResult in $ListOfMovies){
                [pscustomobject]@{
                    MovieName = ($HtmlResult.Attributes | where {$_.name -like 'data-movie'}).Value
                    eventDateTime = ($HtmlResult.Attributes | where {$_.name -like 'data-run'}).Value | Get-Date
                    auditorium = ($HtmlResult.Attributes | where {$_.name -like 'title'}).Value.split(',')[-1].trim()
                    #auditoriumTinyName = ($HtmlResult.ie8_attributes | where {$_.nodename -like 'title'}).Value.split(',')[-1].trim()
                    #BuyLink = ($HtmlResult.Attributes | where {$_.name -like 'data-buy'}).Value
                    CinemaName = $Cinema.DisplayName
                }
            }


            $CineGrandOutput | select MovieName,filmId,eventDateTime,auditorium,auditoriumTinyName,CinemaName

        }


        return $report
        
    }
    
    end {
        
    }
}

function Get-KinoArena {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory, ValueFromPipeline)]
        $SearchDate
        
    )
    
    begin {
                

        <#
        If ( -Not ([System.Management.Automation.PSTypeName]'AngleSharp.Parser.Html.HtmlParser').Type ) {
        $standardAssemblyFullPath = (Get-ChildItem -Filter '*.dll' -Recurse (Split-Path (Get-Package -Name 'AngleSharp').Source)).FullName | Where-Object {$_ -Like "*standard*"} | Select-Object -Last 1

        Add-Type -Path $standardAssemblyFullPath -ErrorAction 'SilentlyContinue'
        } # Terminate If - Not Loaded
        #>

    }
    
    process {

        ####KinoArena#####

        $KinoArenaDate = "$($SearchDate.Date.ToString("dd-MM-yyyy"))"

        

        foreach ($Cinema in $ListOfCinemas | where cname -like 'KinoArena*'){
            $uri = "$($Cinema.LocationURI)/$KinoArenaDate"

            $Request = Invoke-WebRequest -Uri $uri -UseBasicParsing

            $Parser = New-Object AngleSharp.Html.Parser.HtmlParser
            $Parsed = $Parser.ParseDocument($Request.Content)

            $ListOfMovies = $Parsed.All | where classname -like scheduleRow

            $KinoArenaOutput = foreach ($movie in $ListOfMovies){

                $movie.Children[1].Children[1].Children | where ClassName -like 'Row' | foreach {   
                    $row = $_ 
                    $row.Children[1].Children[0].Children | foreach {
                        $itemBooking = $_

                        [pscustomobject]@{
                            MovieName = $movie.Children[1].Children[0].Children[0].Children.TextContent
                            eventDateTime = Get-Date "$($SearchDate.Date.ToShortDateString()) $($itemBooking.Children.TextContent)"
                            auditorium = ($row.Children[0].Children | foreach {$_.Children.title} | sort) -join '; '
                            #auditoriumTinyName = ($HtmlResult.ie8_attributes | where {$_.nodename -like 'title'}).Value.split(',')[-1].trim()
                            CinemaName = $Cinema.DisplayName
                        }
                    
                    }
                }   

            }

            $report += $KinoArenaOutput | select MovieName,filmId,eventDateTime,auditorium,auditoriumTinyName,CinemaName

        }

        return $report
        
    }
    
    end {
        
    }
}

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
        DisplayName = 'CineGrand - Park Center'
    },
    [pscustomobject]@{
        CName = "CineGrand-SofiaRingMall"; 
        CID = 0;
        HomeAddress = 'https://cinegrand.bg/';
        LocationURI = 'https://cinegrand.bg/%D1%81%D0%BE%D1%84%D0%B8%D1%8F-%D1%80%D0%B8%D0%BD%D0%B3-%D0%BC%D0%BE%D0%BB/schedule';
        DisplayName = 'CineGrand - Sofia Ring Mall'
    },


    [pscustomobject]@{
        CName = "KinoArena-TheMall"; 
        CID = 0;
        HomeAddress = 'https://www.kinoarena.com/';
        LocationURI = 'https://www.kinoarena.com/bg/program/view/kino-arena-the-mall';
        DisplayName = 'Kino Arena - The Mall'
    },
    [pscustomobject]@{
        CName = "KinoArena-WestMall"; 
        CID = 0;
        HomeAddress = 'https://www.kinoarena.com/';
        LocationURI = 'https://www.kinoarena.com/bg/program/view/arena-mega-mol';
        DisplayName = 'Kino Arena - West Mall'
    }




$Today = (Get-Date)
$ListOfDates = @()
$ListOfDates += $Today
$ListOfDates += 1..7 | foreach {(Get-date).AddDays($_)}

$Thursday = $ListOfDates | where DayOfWeek -like "Thursday"

$RangeOfDates = $ListOfDates | where {$_ -ge $Today -and $_ -le $Thursday}

$index1 = 0
$RangeOfDatesFormatted = $RangeOfDates | foreach {$index1++ ;  $_ | select @{n='Index';e={$index1}},DayOfWeek,@{n='DateF';e={$_.ToShortDateString()}},Date}


$finalReport = $()
foreach ($SearchDate in $RangeOfDatesFormatted){

    ####CinemaCity#####
    $finalReport += Get-CinemaCity -SearchDate $SearchDate

    ####Cinegrand#####
    $finalReport += Get-CineGrand -SearchDate $SearchDate

    ####KinoArena#####
    $finalReport += Get-KinoArena -SearchDate $SearchDate

    #Start-Sleep -Seconds 3

}


$outputFormat = @(
    @{n='Movie Name'; e={$_.moviename}},
    @{n='DateTime'; e={$_.eventDateTime.ToString("yyyy-MM-ddThh:mm:ss")}},
    @{n='Date'; e={$_.eventDateTime.ToShortDateString()}},
    @{n='Day'; e={$_.eventDateTime.DayOfWeek}},
    @{n='Time'; e={$_.eventDateTime.ToShortTimeString()}},
    @{n='Screen'; e={if($_.auditoriumTinyName){$_.auditoriumTinyName} else{$_.auditorium}}},
    @{n='Cinema Name'; e={$_.CinemaName}}
)

#$FilteredMovies | select $outputFormat | ft -AutoSize

$FilteredMovies = $finalReport | select $outputFormat


#$FilteredMovies | Export-Csv 'F:\OneDrive\Folders\Powershell Scripts\CinemaSearch-Git\CinemaSearch\data.csv' -NoTypeInformation -Force
#$FilteredMovies | Out-GridView




##Get and update the CSV:

$headers = @{
    Authorization = "token $env:GITHUB_TOKEN"
    Accept        = "application/vnd.github.v3+json"
}

$owner = "darakion"
$repo  = "CinemaSearch"
$path  = "data.csv"

$response = Invoke-RestMethod `
  -Uri "https://api.github.com/repos/$owner/$repo/contents/$($path)?ref=main" `
  -Headers $headers `
  -Method Get


#$currentCsv = [System.Text.Encoding]::UTF8.GetString(
#    [Convert]::FromBase64String($response.content)
#)


$updatedcsv = $FilteredMovies | ConvertTo-Csv -NoTypeInformation


$encoded = [Convert]::ToBase64String(
    [System.Text.Encoding]::UTF8.GetBytes($updatedCsv)
)

$body = @{
    message = "Auto-update CSV via Azure Function"
    content = $encoded
    sha     = $response.sha
} | ConvertTo-Json -Depth 10

Invoke-RestMethod `
  -Uri "https://api.github.com/repos/$owner/$repo/contents/$($path)?ref=main" `
  -Headers $headers `
  -Method Put `
  -Body $body




## END
Push-OutputBinding -Name Response -Value @{
    statusCode = 200
    body = "CSV updated successfully"
}