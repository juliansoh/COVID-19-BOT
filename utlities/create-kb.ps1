$QnACogServiceKey = "" 
$kbAppServiceEndpoint ""
$kbName = ""

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Ocp-Apim-Subscription-Key", $QnACogServiceKey)

$body = "{`"name`": `"$kbName`",`"urls`": [`"https://www.cdc.gov/coronavirus/2019-ncov/faq.html`"]}"

$createResponse = Invoke-RestMethod 'https://westus.api.cognitive.microsoft.com/qnamaker/v4.0/knowledgebases/create' -Method 'POST' -Headers $headers -Body $body
$createResponse | ConvertTo-Json

Do {
Write-Host "waiting to check status of create operation..."
Start-Sleep -s 15
$createStatusResponse = Invoke-RestMethod "https://westus.api.cognitive.microsoft.com/qnamaker/v4.0/operations/$($createResponse.operationId)" -Method 'GET' -Headers $headers
$createStatusResponse | ConvertTo-Json
}
While ($createStatusResponse.operationState -eq "NotStarted" -or $createStatusResponse.operationState -eq "Running")

If ($createStatusResponse.operationState -eq "Succeeded")
{
    #publish the kb, investigate invoke-webrequest to catch 204 (processed, but no response code)
    $publishResponse = Invoke-RestMethod "https://westus.api.cognitive.microsoft.com/qnamaker/v4.0/$($createStatusResponse.resourceLocation)" -Method 'POST' -Headers $headers
    $publishResponse | ConvertTo-Json


    $runtimeKeyResponse = Invoke-RestMethod 'https://westus.api.cognitive.microsoft.com/qnamaker/v4.0/endpointkeys' -Method 'GET' -Headers $headers
    $runtimeKeyResponse | ConvertTo-Json

    $question = "{`"question`": `"Should I wear a mask?`"} "

    $headers.Remove("Ocp-Apim-Subscription-Key")
    $headers.Add("Authorization", "EndpointKey $($runtimeKeyResponse.primaryEndpointKey)")
    $questionResponse = Invoke-RestMethod "https://$kbAppServiceEndpoint/qnamaker$($createStatusResponse.resourceLocation)/generateAnswer" -Method 'POST' -Headers $headers -Body $question
    $questionResponse | ConvertTo-Json
}
