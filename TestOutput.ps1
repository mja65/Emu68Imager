


function Write-StartTaskMessage {
    param (
        $Message
    )
    Write-Host ''
    Write-Host $Message -ForegroundColor White
    Write-Host ''
}

function Write-InformationMessage {
    param (
        $Message
    )
    Write-Host $Message -ForegroundColor Yellow
}

function Write-ErrorMessage {
    param (
        $Message
    )
    Write-Host "[ERROR] `t $Message" -ForegroundColor Red
}

function Write-TaskCompleteMessage {
    param (
        $Message
    )
    Write-Host $Message -ForegroundColor Green
}

Write-StartTaskMessage -Message 'test'
Write-InformationMessage -Message 'test'
Write-ErrorMessage -Message 'test'
Write-TaskCompleteMessage -Message 'test'