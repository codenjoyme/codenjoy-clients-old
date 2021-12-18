
#default public server URI
#[URI]$Global:HeroURI = "ws://codenjoy.com:80/codenjoy-contest/ws?user=donNetClient@dot.net"

#default local server URI
[URI]$Global:HeroURI = "ws://127.0.0.1:8080/codenjoy-contest/ws?user=username@users.org"


#region BASIC functions

function Invoke-GameSync {
[CmdletBinding()]
[Alias("Move")]

Param
(
    # $Global:HeroAction is the game action to send to server
    [Parameter(Mandatory=$false, 
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true, 
               Position=0)]
	[ValidateSet("wait","act","left","right","up","down","act, left","act, right","act, up","act, down","left, act","right, act","up, act","down, act")]
	[String]$NextAction = "wait"
)

Begin
{
	# verbose info
	Write-Verbose ("`n`n`n Starting new sync")
	$SyncStartTime = (Get-Date)
	$SyncTime = (New-TimeSpan -Seconds 0)

	# Open websocket connection 
	If ($ClientWebSocket.State -ne "Open")
	{
		$global:ClientWebSocket = New-Object System.Net.WebSockets.ClientWebSocket
		$global:CancellationToken = New-Object System.Threading.CancellationToken
		
		$ConnectAsync = $ClientWebSocket.ConnectAsync($Global:HeroURI, $CancellationToken)
		
		$myCustomTimeout = New-TimeSpan -Seconds 3
		$myActionStartTime = Get-Date

		While (!$ConnectAsync.IsCompleted) 
		{ 
			$TimeTaken = (get-date) - $myActionStartTime
			If ($TimeTaken -gt $myCustomTimeout) 
				{
					Write-Warning ("Warning: ConnectAsync ID" + $ConnectAsync.Id.ToString() + " taking longer than " + ($myCustomTimeout.seconds) +" seconds.")
					Return
				}
			Start-Sleep -Milliseconds 50 
		}
		
		Write-Verbose ("ConnectAsync ID " + $ConnectAsync.Id.ToString() + " status: " + ($ConnectAsync.Status))
	}
	Else 
	{
		Write-Verbose ("Websocked already opened")
	}
		

	# verbose info
	$SyncTime = ((Get-Date) - $SyncStartTime)
	Write-Verbose ("Synctime after connect $($SyncTime.TotalMilliseconds) Milliseconds " )
}

Process
{
		
	#region Send websocket message
	Write-Verbose ("----- Sync start. SendCounter: $global:SendCounter ReceiveCounter: $global:ReceiveCounter -------")

	# Enumeration of strings which game server able to accept and handle as proper bot action 
	$PossibleActionsEnum = 	"wait","act","left","right","up","down","act, left","act, right","act, up","act, down","left, act","right, act","up, act","down, act"
				
	# Check whether it is a proper string or not
	If ($NextAction -in $PossibleActionsEnum)
	{
		
		# Actually performing websocket SendAsync method 
		$OutgoingBufferArray = [System.Text.Encoding]::UTF8.GetBytes($NextAction)
		$OutgoingData = New-Object System.ArraySegment[byte]  -ArgumentList @(,$OutgoingBufferArray)
				
		$SendAsync = $ClientWebSocket.SendAsync($OutgoingData, [System.Net.WebSockets.WebSocketMessageType]::Text, [System.Boolean]::TrueString, $CancellationToken)
		Start-Sleep -Milliseconds 50

		$Timeout = (New-TimeSpan -Seconds 1)
		$TaskStartTime = (Get-Date)
		
		While (!$SendAsync.IsCompleted) 
		{ 
			$TimeTaken = (Get-Date) - $TaskStartTime
			If ($TimeTaken -gt $Timeout) 
				{
					Write-Warning ("Warning: $SendAsync ID" + $SendAsync.Id.ToString() + " taking longer than " + ($Timeout.seconds) +" seconds.")
					Return
				}
			Start-Sleep -Milliseconds 50
		}
		
		
		# Just verbose troubleshoot data
		$global:ACTUALSendCounter++
		Write-Verbose ("ACTUAL SendAsync performed $($global:ACTUALSendCounter) times")
		Write-Verbose ("ACTUAL SendAsync Status: $($SendAsync.Status)")
		
	}
		
	# Notification about incorrect outgoing message.
	Else
	{
		Write-Warning ("Next game action unrecognized. Try one of the following: ")
		$PossibleActionsEnum.ForEach({Write-Warning $_})
			
	}
		
	$global:SendCounter++
	
	$SyncTime = ((Get-Date) - $SyncStartTime)
	Write-Verbose ("Synctime after send $($SyncTime.TotalMilliseconds) Milliseconds " )
		
	#endregion Send websocket message





	#region RECIEVE websocket message 
		
	# recieve full websocket message until ReceiveAsync.Result.EndOfMessage will be true
	[string]$GameBoardRawString = ""
	[string]$partialGameBoardRawString = ""
	
	Do
	{
		$IncomingBufferArray = [byte[]] @(,0) * 2000
		$IncomingData = New-Object System.ArraySegment[byte]  -ArgumentList @(,$IncomingBufferArray)
		
		$ReceiveAsync = $ClientWebSocket.ReceiveAsync($IncomingData, $CancellationToken)
		
		$Timeout = (New-TimeSpan -Seconds 1)
		$TaskStartTime = (Get-Date)

		While (!$ReceiveAsync.IsCompleted) 
		{ 
			$TimeTaken = ((get-date) - $TaskStartTime)
			If ($TimeTaken -gt $Timeout) 
				{
					Write-Warning ("Warning: $ReceiveAsync ID" + $ReceiveAsync.Id.ToString() + " taking longer than " + ($Timeout.seconds) +" seconds.")
					Return
				}
			Start-Sleep -Milliseconds 100 
		}
		
		
		$partialGameBoardRawString = [System.Text.Encoding]::UTF8.GetString($IncomingData.Array)
		$partialGameBoardRawString = ($partialGameBoardRawString -replace "�", "")
		$GameBoardRawString = $GameBoardRawString + $partialGameBoardRawString.TrimEnd([char]$null)
		
		Write-Verbose ("ReceiveAsync ID " + $ReceiveAsync.Id.ToString() + " status: " + ($ReceiveAsync.Status))
		Write-Verbose ("ReceiveAsync result: Count " + $ReceiveAsync.Result.Count + " EndOfMessage " + $ReceiveAsync.Result.EndOfMessage)
		Write-Verbose ("Gameboard string lenght is $($GameBoardRawString.Length) " )

		$SyncTime = ((Get-Date) - $SyncStartTime)
		Write-Verbose ("Synctime after single receive cycle $($SyncTime.TotalMilliseconds) Milliseconds " )
		
	}
	Until ($ReceiveAsync.Result.EndOfMessage)
		
	$global:ReceiveCounter++
	#endregion Recieve websocket message 

	$SyncTime = ((Get-Date) - $SyncStartTime)
	Write-Verbose ("Synctime after all receives  $($SyncTime.TotalMilliseconds) Milliseconds " )
	
	# Aligning send/rcv sync with 1 sec timeframe
	If ($SyncTime.TotalMilliseconds -lt 900)
	{
		$delay = (900 - $SyncTime.TotalMilliseconds)
		Start-Sleep -Milliseconds $delay
		Write-Verbose ("Added delay  $($delay) Milliseconds " )
	}
	 
}
End
{
	# clean up system resources 
	$SendAsync.Dispose()
	$ReceiveAsync.Dispose()
	#$ClientWebSocket.Abort()
	#$ClientWebSocket.Dispose()
	
	# verbose info
	Write-Verbose ("----- Sync end. SendCounter: $global:SendCounter ReceiveCounter: $global:ReceiveCounter -------")
	$SyncTime = ((Get-Date) - $SyncStartTime)
	Write-Verbose ("Synctime before exit  $($SyncTime.TotalMilliseconds) Milliseconds " )
	
	[string]$Global:CurrentGameBoardRawString = [string]$GameBoardRawString
}
}

function Show-GameBoardRawGrid {
[CmdletBinding()]
[Alias()]
[OutputType([string])]
Param 
(
	# [string]GameBoardRawString
    [Parameter(Mandatory=$false, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
	[ValidateLength(1090,4000)]
    [string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString
)

Begin
{
}
Process
{

	# Cutting string to exclude board=
	$GridGameBoard = $GameBoardRawString.Substring(6)

	# Converting string into grid
	$offset = 0
	$newLineIndex = 33
	for ($newLineIndex = 33; $newLineIndex -lt 1089; $newLineIndex = $newLineIndex + 33)
	{ 
		$GridGameBoard = ($GridGameBoard.Insert(($newLineIndex + $offset),"`n"))
		$offset++		
	} 
	
}
End
{
	Write-Output $GridGameBoard
}
}

function Get-GameBoardCharArray {
[CmdletBinding()]
[Alias()]
[OutputType([String[,]])]
Param
(
	# [string]GameBoardRawString
    [Parameter(Mandatory=$false, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
	[ValidateLength(1090,2000)]
    [string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString

)
Begin
{
}
Process
{
	$boardString = $GameBoardRawString.Substring(6)
	[int]$GameStringCounter = 0
	$GameBoardCharsArray = New-Object 'string[,]' 33,33

	for ($y=0; $y -lt $GameBoardCharsArray.GetLength(1); $y++) 
	{
		for ($x=0; $x -lt $GameBoardCharsArray.GetLength(0); $x++) 
		{
			$GameBoardCharsArray[$x,$y] = $boardString[$GameStringCounter]
			$GameStringCounter++
		}
	}
}
End
{
	Return , [string[,]]$GameBoardCharsArray
}
}

function Show-GameBoardCharArray {
[CmdletBinding()]
[Alias()]
Param
(
	# [string]GameBoardRawString
    [Parameter(Mandatory=$false, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
	[ValidateLength(1090,2000)]
    [string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString
)
Begin
{
}
Process
{
	$boardString = $GameBoardRawString.Substring(6)
	[int]$GameStringCounter = 0
	$GameCharsArray = New-Object 'string[,]' 33,33

	for ($y=0; $y -lt $GameCharsArray.GetLength(1); $y++) 
	{
		[string]$CharsLine = ""
		for ($x=0; $x -lt $GameCharsArray.GetLength(0); $x++) 
		{
			$CharsLine = $CharsLine + $boardString[$GameStringCounter]
			$GameStringCounter++
		}
		Write-Output $CharsLine
	}
}
End
{
}
}

function Get-GameBoardElementArray {
[CmdletBinding()]
[Alias()]
[OutputType([String[,]])]
Param
(
	# [string]GameBoardRawString
    [Parameter(Mandatory=$false, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
	[ValidateLength(1090,2000)]
    [string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString

)
Begin
{		
}
Process
{
	$boardString = $GameBoardRawString.Substring(6)
	$GameBoardElementArray = New-Object 'string[,]' 33,33
	[int]$GameStringCounter = 0

	for ($y=0; $y -lt $GameBoardElementArray.GetLength(1); $y++) 
	{
		for ($x=0; $x -lt $GameBoardElementArray.GetLength(0); $x++) 
		{
			
			switch ($boardString[$GameStringCounter])
			{
            ## your Molly

                # This is what she usually looks like.
                '☺'
                {
                    $GameBoardElementArray[$x,$y] = 'Hero'
                }

                # This is if she is sitting on own potion.
                '☻'
                {
                    $GameBoardElementArray[$x,$y] = 'PotionHero'
                }

                # Oops, your Molly is dead (don't worry,
                # she will appear somewhere in next move).
                # You're getting penalty points for each death.
                'Ѡ'
                {
                    $GameBoardElementArray[$x,$y] = 'DeadHero'
                }

            ## other players heroes

                # This is what other heroes looks like.
                '♥'
                {
                    $GameBoardElementArray[$x,$y] = 'OtherHero'
                }

                # This is if player is sitting on own potion.
                '♠'
                {
                    $GameBoardElementArray[$x,$y] = 'OtherPotionHero'
                }

                # Enemy corpse (it will disappear shortly,
                # right on the next move).
                # If you've done it you'll get score points.
                '♣'
                {
                    $GameBoardElementArray[$x,$y] = 'OtherDeadHero'
                }

            ## the potions
                # After Molly set the potion, the timer starts (5 ticks).
                '5'
                {
                    $GameBoardElementArray[$x,$y] = 'PotionTimer5'
                }

                # This will blow up after 4 ticks.
                '4'
                {
                    $GameBoardElementArray[$x,$y] = 'PotionTimer4'
                }

                # This after 3...
                '3'
                {
                    $GameBoardElementArray[$x,$y] = 'PotionTimer3'
                }

                # Two..
                '2'
                {
                    $GameBoardElementArray[$x,$y] = 'PotionTimer2'
                }

                # One.
                '1'
                {
                    $GameBoardElementArray[$x,$y] = 'PotionTimer1'
                }

                # Boom! this is what is potion does,
                # everything that is destroyable got destroyed.
                '҉'
                {
                    $GameBoardElementArray[$x,$y] = 'Boom'
                }

            ## walls

                # Indestructible wall - it will not fall from potion.
                '☼'
                {
                    $GameBoardElementArray[$x,$y] = 'Wall'
                }

                # this is a treasure box, it opens with an explosion.
                '#'
                {
                    $GameBoardElementArray[$x,$y] = 'TreasureBox'
                }

                # this is like a treasure box opens looks
                # like, it will disappear on next move.
                # if it's you did it - you'll get score
                # points. Perhaps a prize will appear.
                'H'
                {
                    $GameBoardElementArray[$x,$y] = 'OpeningTreasureBox'
                }

            ## soulless creatures

                # This guys runs over the board randomly
                # and gets in the way all the time.
                # If it will touch Molly - she will die.
                # You'd better kill this piece of ... soul,
                # you'll get score points for it.
                '&'
                {
                    $GameBoardElementArray[$x,$y] = 'Ghost'
                }

                # This is ghost corpse.
                'x'
                {
                    $GameBoardElementArray[$x,$y] = 'DeadGhost'
                }

            ## perks

                # Potion blast radius increase.
                # Applicable only to new potions.
                # The perk is temporary.
                '+'
                {
                    $GameBoardElementArray[$x,$y] = 'PotionBlastRadiusIncrease'
                }

                # Increase available potions count.
                # Number of extra potions can be set
                # in settings. Temporary.
                'c'
                {
                    $GameBoardElementArray[$x,$y] = 'PotionCountIncrease'
                }

                # Potion blast not by timer but by second act.
                # Number of RC triggers is limited and c
                # an be set in settings.
                'r'
                {
                    $GameBoardElementArray[$x,$y] = 'PotionRemoteControl'
                }

                # Do not die after potion blast
                # (own potion and others as well). Temporary.
                'i'
                {
                    $GameBoardElementArray[$x,$y] = 'PotionImmune'
                }

            ## a void

                # This is the only place where you can move your Molly.
                ' '
                {
                    $GameBoardElementArray[$x,$y] = 'Space'
                }

				# Empty space on a map. This is the only place where you can move your Hero
				Default
				{
					$GameBoardElementArray[$x,$y] = 'None'
				}
			}
			
			$GameStringCounter++
		}
	}
}
End
{
	Return , [string[,]]$GameBoardElementArray
}
}

function Get-GameElementCollection {
[CmdletBinding()]
[Alias()]
Param
(
	# [string]GameBoardRawString
    [Parameter(Mandatory=$false, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
	[ValidateLength(1090,2000)]
    [string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString,

	# [string]Element
    [Parameter(Mandatory=$true, 
               Position=0)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(
		"Hero",
		"PotionHero",
		"DeadHero",
		"OtherHero",
		"OtherPotionHero",
		"OtherDeadHero",
		"PotionTimer5",
		"PotionTimer4",
		"PotionTimer3",
		"PotionTimer2",
		"PotionTimer1",
		"Boom",
		"Wall",
		"TreasureBox",
		"OpeningTreasureBox",
		"Ghost",
		"DeadGhost",
		"None")]
    [string]$Element

)
Begin
{
}
Process
{
	$HeroCollection = New-Object System.Collections.Generic.List[System.Object]
	$PotionHeroCollection = New-Object System.Collections.Generic.List[System.Object]
	$DeadHeroCollection = New-Object System.Collections.Generic.List[System.Object]
	$OtherHeroCollection = New-Object System.Collections.Generic.List[System.Object]
	$OtherPotionHeroCollection = New-Object System.Collections.Generic.List[System.Object]
	$OtherDeadHeroCollection = New-Object System.Collections.Generic.List[System.Object]
	$PotionTimer5Collection = New-Object System.Collections.Generic.List[System.Object]
	$PotionTimer4Collection = New-Object System.Collections.Generic.List[System.Object]
	$PotionTimer3Collection = New-Object System.Collections.Generic.List[System.Object]
	$PotionTimer2Collection = New-Object System.Collections.Generic.List[System.Object]
	$PotionTimer1Collection = New-Object System.Collections.Generic.List[System.Object]
	$BoomCollection = New-Object System.Collections.Generic.List[System.Object]
	$WallCollection = New-Object System.Collections.Generic.List[System.Object]
	$TreasureBoxCollection = New-Object System.Collections.Generic.List[System.Object]
	$OpeningTreasureBoxCollection = New-Object System.Collections.Generic.List[System.Object]
	$GhostCollection = New-Object System.Collections.Generic.List[System.Object]
	$DeadGhostCollection = New-Object System.Collections.Generic.List[System.Object]
	$NoneCollection = New-Object System.Collections.Generic.List[System.Object]
	
	$boardString = $GameBoardRawString.Substring(6)
	[int]$GameStringCounter = 0
	$GameBoardElementArray = New-Object 'string[,]' 33,33

	for ($y=0; $y -lt $GameBoardElementArray.GetLength(1); $y++) 
	{
		for ($x=0; $x -lt $GameBoardElementArray.GetLength(0); $x++) 
		{
			
			switch ($boardString[$GameStringCounter])
			{
				# This is your Hero. This is what he usually looks like
				'☺'
				{
					$point = $null
					$point = ($x,$y)
					$HeroCollection.Add($point)
					$point = $null
				}

				# Your hero is sitting on own bomb
				'☻'
				{
					$point = $null
					$point = ($x,$y)
					$PotionHeroCollection.Add($point)
					$point = $null
				} 
				
				# Your dead Hero. Don't worry, he will appear somewhere in next move. You're getting -200 for each death
				'Ѡ'
				{
					$point = $null
					$point = ($x,$y)
					$DeadHeroCollection.Add($point)
					$point = $null
				}

				# This is other players alive Hero
				'♥'
				{
					$point = $null
					$point = ($x,$y)
					$OtherHeroCollection.Add($point)
					$point = $null
				}
				
				# This is other players Hero -  just set the bomb
				'♠'
				{
					$point = $null
					$point = ($x,$y)
					$OtherPotionHeroCollection.Add($point)
					$point = $null
				}

				# Other players Hero's corpse. It will disappear shortly, right on the next move. If you've done it you'll get +1000
				'♣'
				{
					$point = $null
					$point = ($x,$y)
					$OtherDeadHeroCollection.Add($point)
					$point = $null
				}
		
				# Potion with timer "5 tacts to boo-o-o-m!". After hero set the bomb, the timer starts (5 tacts)
				'5'
				{
					$point = $null
					$point = ($x,$y)
					$PotionTimer5Collection.Add($point)
					$point = $null
				}

				# Potion with timer "4 tacts to boom"
				'4'
				{
					$point = $null
					$point = ($x,$y)
					$PotionTimer4Collection.Add($point)
					$point = $null
				}

				# Potion with timer "3 tacts to boom"
				'3'
				{
					$point = $null
					$point = ($x,$y)
					$PotionTimer3Collection.Add($point)
					$point = $null
				}

				# Potion with timer "2 tacts to boom"
				'2'
				{
					$point = $null
					$point = ($x,$y)
					$PotionTimer2Collection.Add($point)
					$point = $null
				}

				# Potion with timer "1 tacts to boom"
				'1'
				{
					$point = $null
					$point = ($x,$y)
					$PotionTimer1Collection.Add($point)
					$point = $null
				}

				# Boom! This is what is bomb does, everything that is destroyable got destroyed
				'҉'
				{
					$point = $null
					$point = ($x,$y)
					$BoomCollection.Add($point)
					$point = $null
				}

				# Wall that can't be destroyed. Indestructible wall will not fall from bomb.
				'☼'
				{
					$point = $null
					$point = ($x,$y)
					$WallCollection.Add($point)
					$point = $null
				}
				
				# Destroyable wall. It can be blowed up with a bomb (+10 points)
				'#'
				{
					$point = $null
					$point = ($x,$y)
					$TreasureBoxCollection.Add($point)
					$point = $null
				}

				# Walls ruins. This is how broken wall looks like, it will dissapear on next move.
				'H'
				{
					$point = $null
					$point = ($x,$y)
					$OpeningTreasureBoxCollection.Add($point)
					$point = $null
				}

				# Ghost. This guys runs over the board randomly and gets in the way all the time. If it will touch hero - hero dies.
				'&'
				{
					$point = $null
					$point = ($x,$y)
					$GhostCollection.Add($point)
					$point = $null
				}

				# Dead ghost. +100 point for killing.
				'x'
				{
					$point = $null
					$point = ($x,$y)
					$DeadGhostCollection.Add($point)
					$point = $null
				}

				# Empty space on a map. This is the only place where you can move your Hero
				Default
				{
					$point = $null
					$point = ($x,$y)
					$NoneCollection.Add($point)
					$point = $null
				}
			}
			
			$GameStringCounter++
		}
	}
}
End
{
	switch ($Element)
	{
	"Hero" {Return , $HeroCollection}
	"PotionHero" {Return , $PotionHeroCollection}
	"DeadHero"{Return , $DeadHeroCollection}
	"OtherHero"{Return , $OtherHeroCollection}
	"OtherPotionHero"{Return , $OtherPotionHeroCollection}
	"OtherDeadHero"{Return , $OtherDeadHeroCollection}
	"PotionTimer5"{Return , $PotionTimer5Collection}
	"PotionTimer4"{Return , $PotionTimer4Collection}
	"PotionTimer3"{Return , $PotionTimer3Collection}
	"PotionTimer2"{Return , $PotionTimer2Collection}
	"PotionTimer1"{Return , $PotionTimer1Collection}
	"Boom"{Return , $BoomCollection}
	"Wall"{Return , $WallCollection}
	"TreasureBox"{Return , $TreasureBoxCollection}
	"OpeningTreasureBox"{Return , $OpeningTreasureBoxCollection}
	"Ghost"{Return , $GhostCollection}
	"DeadGhost"{Return , $DeadGhostCollection}
	"None"{Return , $NoneCollection}
    Default {Write-Output "Something went wrong."}
	}
}
}
 
#endregion



#region HELPER functions

function getHero {
    [CmdletBinding()]
    [Alias()]
    
    Param
    (
		# [string]GameBoardRawString
		[Parameter(Mandatory=$false, 
					ValueFromPipeline=$true,
					ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[ValidateLength(1090,2000)]
		[string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString
	)

    Begin
    {
    }
    Process
    {
        $Hero = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element Hero
		$PotionHero = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element PotionHero
		$DeadHero = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element DeadHero
		$myHero = $Hero + $PotionHero + $DeadHero
    }
    End
    {
		Return , $myHero
    }
}

function getOtherHeroes {
    [CmdletBinding()]
    [Alias()]
    
    Param
    (
		# [string]GameBoardRawString
		[Parameter(Mandatory=$false, 
					ValueFromPipeline=$true,
					ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[ValidateLength(1090,2000)]
		[string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString
	)

    Begin
    {
    }
    Process
    {
        $OtherHero = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element OtherHero
		$OtherPotionHero = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element OtherPotionHero
		$OtherDeadHero = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element OtherDeadHero
		$OtherHeroes = $OtherHero + $OtherPotionHero + $OtherDeadHero
    }
    End
    {
		Return , $OtherHeroes
    }
}

function isGameOver {
    [CmdletBinding()]
    [Alias()]
    
    Param
    (
		# [string]GameBoardRawString
		[Parameter(Mandatory=$false, 
					ValueFromPipeline=$true,
					ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[ValidateLength(1090,2000)]
		[string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString
	)

    Begin
    {
    }
    Process
    {
        $DeadHero = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element DeadHero
		If ($DeadHero.Count -eq 1) {Return $true}
		Else {Return $false}
    }
    End
    {
		
    }
}

function isAt {
[CmdletBinding()]
[Alias()]
Param
(
	# [string]GameBoardRawString
    [Parameter(Mandatory=$false, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
				ParameterSetName='by single element')]
	[Parameter(Mandatory=$false, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
				ParameterSetName='by array of elements')]
    [ValidateNotNullOrEmpty()]
	[ValidateLength(1090,2000)]
    [string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString,

	# [int]x
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=0)]
	[Parameter(Mandatory=$true,
				ParameterSetName='by array of elements',
                Position=0)]
	[ValidateRange(0,32)]
    [ValidateNotNullOrEmpty()]
    [int]$X,

	# [int]y
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=1)]
	[Parameter(Mandatory=$true,
				ParameterSetName='by array of elements',
                Position=1)]
	[ValidateRange(0,32)]
    [ValidateNotNullOrEmpty()]
    [int]$Y,
	
	
	# [string]Element
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=2)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(
		"Hero",
		"PotionHero",
		"DeadHero",
		"OtherHero",
		"OtherPotionHero",
		"OtherDeadHero",
		"PotionTimer5",
		"PotionTimer4",
		"PotionTimer3",
		"PotionTimer2",
		"PotionTimer1",
		"Boom",
		"Wall",
		"TreasureBox",
		"OpeningTreasureBox",
		"Ghost",
		"DeadGhost",
		"None")]
    [string]$Element,
		
	
	# [string[]]Elements
    [Parameter(Mandatory=$true,
				ParameterSetName='by array of elements',
                Position=2)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(
		"Hero",
		"PotionHero",
		"DeadHero",
		"OtherHero",
		"OtherPotionHero",
		"OtherDeadHero",
		"PotionTimer5",
		"PotionTimer4",
		"PotionTimer3",
		"PotionTimer2",
		"PotionTimer1",
		"Boom",
		"Wall",
		"TreasureBox",
		"OpeningTreasureBox",
		"Ghost",
		"DeadGhost",
		"None")]
    [string[]]$Elements

)
Begin
{
}
Process
{
	
	switch ($PsCmdlet.ParameterSetName)
    {
		'by single element'
		{
			$GameBoard = Get-GameBoardElementArray -GameBoardRawString $GameBoardRawString
			If ($GameBoard[($x),($y)] -match $Element) {Return $true}
			Else {Return $false}
		}

		'by array of elements'
		{
			$GameBoard = Get-GameBoardElementArray -GameBoardRawString $GameBoardRawString
			If ($GameBoard[($x),($y)] -iin $Elements) {Return $true}
			Else {Return $false}
		}
    
	} 
	
	
}
End
{

}
}

function isNear {
[CmdletBinding()]
[Alias()]
Param
(
	# [string]GameBoardRawString
    [Parameter(Mandatory=$false, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
				ParameterSetName='by single element')]
    [ValidateNotNullOrEmpty()]
	[ValidateLength(1090,2000)]
    [string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString,

	# [int]x
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=0)]
	[ValidateRange(0,32)]
    [ValidateNotNullOrEmpty()]
    [int]$X,

	# [int]y
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=1)]
	[ValidateRange(0,32)]
    [ValidateNotNullOrEmpty()]
    [int]$Y,
	
	
	# [string]Element
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=2)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(
		"Hero",
		"PotionHero",
		"DeadHero",
		"OtherHero",
		"OtherPotionHero",
		"OtherDeadHero",
		"PotionTimer5",
		"PotionTimer4",
		"PotionTimer3",
		"PotionTimer2",
		"PotionTimer1",
		"Boom",
		"Wall",
		"TreasureBox",
		"OpeningTreasureBox",
		"Ghost",
		"DeadGhost",
		"None")]
    [string]$Element

)
Begin
{
}
Process
{
	
	$GameBoard = Get-GameBoardElementArray -GameBoardRawString $GameBoardRawString
	If 
	(
		($GameBoard[($x+1),($y)]),
		($GameBoard[($x-1),($y)]),
		($GameBoard[($x),($y+1)]),
		($GameBoard[($x),($y-1)]) -contains $Element
	) 
	{Return $true} 
	Else
	{Return $false}
	


	
	
	
}
End
{

}
}

function isBarrierAt {
[CmdletBinding()]
[Alias()]
Param
(
	# [string]GameBoardRawString
    [Parameter(Mandatory=$false, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
				ParameterSetName='by single element')]
    [ValidateNotNullOrEmpty()]
	[ValidateLength(1090,2000)]
    [string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString,

	# [int]x
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=0)]
	[ValidateRange(0,32)]
    [ValidateNotNullOrEmpty()]
    [int]$X,

	# [int]y
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=1)]
	[ValidateRange(0,32)]
    [ValidateNotNullOrEmpty()]
    [int]$Y
)
Begin
{
}
Process
{
	
	$GameBoard = Get-GameBoardElementArray -GameBoardRawString $GameBoardRawString
	If ($GameBoard[($x),($y)] -iin "Wall","TreasureBox") {Return $true}
	Else {Return $false}
	
}
End
{

}
}

function countNear {
[CmdletBinding()]
[Alias()]
Param
(
	# [string]GameBoardRawString
    [Parameter(Mandatory=$false, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
				ParameterSetName='by single element')]
    [ValidateNotNullOrEmpty()]
	[ValidateLength(1090,2000)]
    [string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString,

	# [int]x
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=0)]
	[ValidateRange(0,32)]
    [ValidateNotNullOrEmpty()]
    [int]$X,

	# [int]y
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=1)]
	[ValidateRange(0,32)]
    [ValidateNotNullOrEmpty()]
    [int]$Y,
	
	
	# [string]Element
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=2)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(
		"Hero",
		"PotionHero",
		"DeadHero",
		"OtherHero",
		"OtherPotionHero",
		"OtherDeadHero",
		"PotionTimer5",
		"PotionTimer4",
		"PotionTimer3",
		"PotionTimer2",
		"PotionTimer1",
		"Boom",
		"Wall",
		"TreasureBox",
		"OpeningTreasureBox",
		"Ghost",
		"DeadGhost",
		"None")]
    [string]$Element

)
Begin
{
}
Process
{
	
	$GameBoard = Get-GameBoardElementArray -GameBoardRawString $GameBoardRawString
	
	$counter = 0
	$nearElements = ($GameBoard[($x+1),($y)]),($GameBoard[($x-1),($y)]),($GameBoard[($x),($y+1)]),($GameBoard[($x),($y-1)])
	foreach ($currentElement in $nearElements )
	{
		if ($currentElement -match $Element) {$counter++}
	}
		
}
End
{
	Return [int]$counter
}
}

function getAt {
[CmdletBinding()]
[Alias()]
Param
(
	# [string]GameBoardRawString
    [Parameter(Mandatory=$false, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
				ParameterSetName='by single element')]
    [ValidateNotNullOrEmpty()]
	[ValidateLength(1090,2000)]
    [string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString,

	# [int]x
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=0)]
	[ValidateRange(0,32)]
    [ValidateNotNullOrEmpty()]
    [int]$X,

	# [int]y
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=1)]
	[ValidateRange(0,32)]
    [ValidateNotNullOrEmpty()]
    [int]$Y
)
Begin
{
}
Process
{
	
	Return (Get-GameBoardElementArray -GameBoardRawString $GameBoardRawString)[($x),($y)]
	


}
End
{

}
}

function boardSize {
    [CmdletBinding()]
    [Alias()]
    
    Param
    (
		# [string]GameBoardRawString
		[Parameter(Mandatory=$false, 
					ValueFromPipeline=$true,
					ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[ValidateLength(1090,2000)]
		[string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString
	)

    Begin
    {
    }
    Process
    {
        Return ([math]::Sqrt(($GameBoardRawString.Substring(6)).Length))
    }
    End
    {
		
    }
}

function getBarriers {
    [CmdletBinding()]
    [Alias()]
    
    Param
    (
		# [string]GameBoardRawString
		[Parameter(Mandatory=$false, 
					ValueFromPipeline=$true,
					ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[ValidateLength(1090,2000)]
		[string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString
	)

    Begin
    {
    }
    Process
    {
        $Wall = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element Wall
		$TreasureBox = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element TreasureBox
		$TreasureBox = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element PotionTimer1
		$TreasureBox = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element PotionTimer2
		$TreasureBox = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element PotionTimer3
		$TreasureBox = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element PotionTimer4
		$TreasureBox = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element PotionTimer5
		$TreasureBox = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element OtherPotionHero
		$TreasureBox = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element OtherHero
		$TreasureBox = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element Ghost
		
		$Barriers = $Wall + $TreasureBox
    }
    End
    {
		Return , $Barriers
    }
}

function getGhosts {
    [CmdletBinding()]
    [Alias()]
    
    Param
    (
		# [string]GameBoardRawString
		[Parameter(Mandatory=$false, 
					ValueFromPipeline=$true,
					ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[ValidateLength(1090,2000)]
		[string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString
	)

    Begin
    {
    }
    Process
    {
        $Ghost = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element Ghost

    }
    End
    {
		Return , $Ghost
    }
}

function getWalls {
    [CmdletBinding()]
    [Alias()]
    
    Param
    (
		# [string]GameBoardRawString
		[Parameter(Mandatory=$false, 
					ValueFromPipeline=$true,
					ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[ValidateLength(1090,2000)]
		[string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString
	)

    Begin
    {
    }
    Process
    {
        $Walls = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element Wall
		
    }
    End
    {
		Return , $Walls
    }
}

function getTreasureBoxes {
    [CmdletBinding()]
    [Alias()]
    
    Param
    (
		# [string]GameBoardRawString
		[Parameter(Mandatory=$false, 
					ValueFromPipeline=$true,
					ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[ValidateLength(1090,2000)]
		[string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString
	)

    Begin
    {
    }
    Process
    {
		$TreasureBox = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element TreasureBox
    }
    End
    {
		Return , $TreasureBox
    }
}

function getPotions {
    [CmdletBinding()]
    [Alias()]
    
    Param
    (
		# [string]GameBoardRawString
		[Parameter(Mandatory=$false, 
					ValueFromPipeline=$true,
					ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[ValidateLength(1090,2000)]
		[string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString
	)

    Begin
    {
    }
    Process
    {
        $PotionHero = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element PotionHero
		$PotionTimer1 = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element PotionTimer1
		$PotionTimer2 = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element PotionTimer2
		$PotionTimer3 = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element PotionTimer3
		$PotionTimer4 = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element PotionTimer4
		$PotionTimer5 = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element PotionTimer5
		$OtherPotionHero = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element OtherPotionHero
		
		$Potions = $PotionHero + $PotionTimer1 + $PotionTimer2 + $PotionTimer3 + $PotionTimer4 + $PotionTimer5 + $OtherPotionHero

		<#
		
		$Potions = New-Object System.Collections.Generic.List[System.Object]
		if ($PotionHero.Count -gt 0) {$Potions.Add($PotionHero)}
		if ($PotionTimer1.Count -gt 0) {$Potions.Add($PotionTimer1)}
		if ($PotionTimer2.Count -gt 0) {$Potions.Add($PotionTimer2)}
		if ($PotionTimer3.Count -gt 0) {$Potions.Add($PotionTimer3)}
		if ($PotionTimer4.Count -gt 0) {$Potions.Add($PotionTimer4)}
		if ($PotionTimer5.Count -gt 0) {$Potions.Add($PotionTimer5)}
		if ($OtherPotionHero.Count -gt 0) {$Potions.Add($OtherPotionHero)}


		#>



			
		
    }
    End
    {
		Return , $Potions
    }
}

function getBlasts {
    [CmdletBinding()]
    [Alias()]
    
    Param
    (
		# [string]GameBoardRawString
		[Parameter(Mandatory=$false, 
					ValueFromPipeline=$true,
					ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[ValidateLength(1090,2000)]
		[string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString
	)

    Begin
    {
    }
    Process
    {
        $Booms = Get-GameElementCollection -GameBoardRawString $GameBoardRawString -Element Boom

    }
    End
    {
		Return , $Booms
    }
}

function getFutureBlasts {
[CmdletBinding()]
[Alias()]
Param
(
	# [string]GameBoardRawString
    [Parameter(Mandatory=$false, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
				ParameterSetName='by single element')]
    [ValidateNotNullOrEmpty()]
	[ValidateLength(1090,2000)]
    [string]$GameBoardRawString = [string]$Global:CurrentGameBoardRawString

)
Begin
{
}
Process
{
	$FutureBlasts = New-Object System.Collections.Generic.List[System.Object]
	$GameBoard = Get-GameBoardElementArray -GameBoardRawString $GameBoardRawString
	
	#get all bombs coordinates
	$allPotions = getPotions
	
	# check every bomb's potenial blast area
	foreach ($bomb in $allPotions)
	{
		# get current bomb's x,y
		$x = $bomb[0]
		$y = $bomb[1]

		#check right direction 
		if ($GameBoard[($x+1),($y)] -inotin "Wall","TreasureBox")
		{
			$FutureBlast = (($x+1),$y)
			$FutureBlasts.Add($FutureBlast)

			if ($GameBoard[($x+2),($y)] -inotin "Wall","TreasureBox")
			{
				$FutureBlast = (($x+2),$y)
				$FutureBlasts.Add($FutureBlast)
				if ($GameBoard[($x+3),($y)] -inotin "Wall","TreasureBox")
				{
					$FutureBlast = (($x+3),$y)
					$FutureBlasts.Add($FutureBlast)
				}
			}
		
		}

		#check left direction 
		if ($GameBoard[($x-1),($y)] -inotin "Wall","TreasureBox")
		{
			$FutureBlast = (($x-1),$y)
			$FutureBlasts.Add($FutureBlast)

			if ($GameBoard[($x-2),($y)] -inotin "Wall","TreasureBox")
			{
				$FutureBlast = (($x-2),$y)
				$FutureBlasts.Add($FutureBlast)
				if ($GameBoard[($x-3),($y)] -inotin "Wall","TreasureBox")
				{
					$FutureBlast = (($x-3),$y)
					$FutureBlasts.Add($FutureBlast)
				}
			}
		
		}


		#check up direction 
		if ($GameBoard[($x),($y+1)] -inotin "Wall","TreasureBox")
		{
			$FutureBlast = (($x),($y+1))
			$FutureBlasts.Add($FutureBlast)

			if ($GameBoard[($x),($y+2)] -inotin "Wall","TreasureBox")
			{
				$FutureBlast = (($x),($y+2))
				$FutureBlasts.Add($FutureBlast)
				if ($GameBoard[($x),($y+3)] -inotin "Wall","TreasureBox")
				{
					$FutureBlast = (($x),($y+3))
					$FutureBlasts.Add($FutureBlast)
				}
			}
		
		}


		#check down direction 
		if ($GameBoard[($x),($y-1)] -inotin "Wall","TreasureBox")
		{
			$FutureBlast = (($x),($y-1))
			$FutureBlasts.Add($FutureBlast)

			if ($GameBoard[($x),($y-2)] -inotin "Wall","TreasureBox")
			{
				$FutureBlast = (($x),($y-2))
				$FutureBlasts.Add($FutureBlast)
				if ($GameBoard[($x),($y-3)] -inotin "Wall","TreasureBox")
				{
					$FutureBlast = (($x),($y-3))
					$FutureBlasts.Add($FutureBlast)
				}
			}
		
		}

	}

	
	
	
}
End
{
	 Return , $FutureBlasts
}
}

#endregion


# other 
function strpos2xy {
[CmdletBinding()]
[Alias()]

Param 
(
	# gamestring index
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
	[ValidateRange(0,1095)]
    [int]$strIndex
)

Begin
{
}
Process
{
	if ($strIndex -gt 6) {
	
	$boardIndex = $strIndex - 6

	$myX = 0
	$myY = [math]::divrem( $strIndex, 33, [ref]$myX )
	$coordinates = ($myX,$myY)


		}
	
}
End
{
	Return , $coordinates
}
}

function xy2strpos {
[CmdletBinding()]
[Alias()]

Param 
(
	# [int]x
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=0)]
	[ValidateRange(0,32)]
    [ValidateNotNullOrEmpty()]
    [int]$X,

	# [int]y
    [Parameter(Mandatory=$true,
				ParameterSetName='by single element',
                Position=1)]
	[ValidateRange(0,32)]
    [ValidateNotNullOrEmpty()]
    [int]$Y
)

Begin
{
}
Process
{
	
	$strPos = (($Y * 33) + $X) + 6
}
End
{
	Return , $strPos
}
}

         
Export-ModuleMember -Function *












