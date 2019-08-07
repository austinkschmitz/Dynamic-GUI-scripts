 
#region Functions start
<#function Write_PSLOG {
	param (
		$Formlog.Machine
	)
	
	$Script:Synchashlog.Machine = @{}
	$Script:Synchashlog.Machine.$_.Username = 
	$Script:Synchashlog.Machine.Scripts =
	$Script:Synchashlog.Machine.Time = (Get-date -UFormat "%Y:%m:%d")
	Write-PSLOG
}#>


<#
if ( ! $PSISE ){
    # Hide this window if not ran using PS ISE
    $t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
    add-type -name win -member $t -namespace native
    [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)
} 
#>

function Write-StatusBar {
	param (
		$Text = ""
	)
	$statusStrip.Text = "$($Text)"
}

function Watch-Clipboard {

    $script:BaseClipboardcheck  = [System.Windows.Forms.Clipboard]::GetDataObject()
	if ( $Script:Synchash.BaseClipboard -ne $script:BaseClipboardcheck ) { 
		$Script:Synchash.BaseClipboard = $script:BaseClipboardcheck
		<#
		$RegexMachineName = ""
		$RegexIPAddress = ""
		$RegexMachineName = #Sanitized#
		$RegexIPAddress = #Sanitized#

		if($RegexMachineName.Length -gt 6){
			$Script:Synchash.Machine.Text = $RegexMachineName.ToString()
		}else {
			$Script:Synchash.Machine.Text = $RegexIPAddress.ToString()	
		}
		#>
		$Script:Synchash.Machine.Text  = "google.com"
		
		Test-Machine -Machine $Script:Synchash.Machine.Text.Trim()
		$Script:Synchash.Machine.Machine = $Script:Synchash.Machine.Text.Trim()
	}
}

# Pings the Machine and sets the background of the textbox to either red/green. Can add yellow for VPN connection.
function Test-Machine {
	param (
		$Machine
	)
	$Ping = Test-Connection -ComputerName $Machine -Count 1 -Quiet
	if ($ping -eq $true){
		$Script:Synchash.Machine.Backcolor = 'Green'
		Get-Usernamedata
	}else{
		$Script:Synchash.Machine.Backcolor = 'Red'
	}


}

#One of two tickers to run. This will Start the Check of the clipboard for new machine name
function Start-TimerStart {
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 2000     # fire every 2s
    $timer.add_tick({ Watch-Clipboard })
    $timer.start()
}

# This ticker will run the auto-update files from the share server and start adding to the gui.
function Start-CheckFiles {
    $timer1 = New-Object System.Windows.Forms.Timer
    $timer1.Interval = 50000     # fire every 5m
    $timer1.add_tick({ Compare-Files })
    $timer1.start()
}

# Comparing files from local machine to share server location.
function Compare-Files {
	$Dir = $Script:Synchash.Agentdir
	$Dirsize = Get-ChildItem -Path $Dir -ErrorAction SilentlyContinue |  Where-Object {$_.extension -like '.ps1'} 
	$FileshareSize = Get-ChildItem -Path $Script:Synchash.Fileshare -ErrorAction SilentlyContinue |  Where-Object {$_.extension -like '.ps1'} 
	
	if($FileshareSize.Count -ne $Dirsize.Count){
	Update-Buttons
	}
}

# If files are inconsistent then this function copy down the new/updated scripts.
function Update-Buttons  {

	$Dir = $Script:Synchash.Agentdir
	Robocopy.exe "$($Script:Synchash.Fileshare)" "$($Dir)" /MIR /MT:64 
	$Script:Synchash.FlowLayoutPanel.Controls.clear()
	$Script:Synchash.scriptbutton = @{}	
	Start-Button
	
}

# Parces and filters only ps1 and bat files. Add a $Cont += '.extension' to be included into buttons. Before adding the buttons, it will sort the scripts alphabetically. 
function Start-Button {

	$Dir = $Script:Synchash.Agentdir
	$Scripts = (Get-ChildItem -Path $Dir -Recurse) 
	$Cont = '.ps1'
	$Cont += '.bat'
	$Scripts = ($Scripts | Where-Object {($_.extension -like '.ps1') -or ($_.extension -like '.bat')} | Sort-Object)
	$Scripts | ForEach-Object {
		$Script:Synchash.Scripts.("$($_.basename)") = $_.fullname
		Add-Button -Buttons $_.BaseName
		#Write-Host "Added $_ to Panel"
	}
	
}

# This will dynamically add the buttons respectively in alphabetical order to the flowpanel
function Add-Button {
	param (
		$Buttons
	)
	$Trimmed = $Buttons
	#$Script:Synchash.scriptbutton.clear()

	$Script:Synchash.scriptbutton.("$($Trimmed)") = @{
		button = New-Object System.Windows.Forms.Button
		ToolTip = New-Object System.Windows.Forms.ToolTip
	}
	$Script:Synchash.scriptbutton.("$($Trimmed)").button.Name = $Trimmed
	$Script:Synchash.scriptbutton.("$($Trimmed)").button.Text = $Trimmed
	$Script:Synchash.scriptbutton.("$($Trimmed)").button.Size = New-Object System.Drawing.Size(84, 66)
	$Script:Synchash.scriptbutton.("$($Trimmed)").button.TabIndex = 0
	$Script:Synchash.scriptbutton.("$($Trimmed)").button.UseVisualStyleBackColor = $true
	$Script:Synchash.scriptbutton.("$($Trimmed)").button.AutoSize = $true
	$Script:Synchash.scriptbutton.("$($Trimmed)").button.ADD_Click({Start-Action})

	
	$Tip = (Get-Help $Script:Synchash.Scripts.("$($_.basename)") -ErrorAction SilentlyContinue).Synopsis 
	$Script:Synchash.scriptbutton.("$($Trimmed)").ToolTip.SetToolTip($Script:Synchash.scriptbutton.("$($Trimmed)").button, "$($TIP)")

	$Script:Synchash.FlowLayoutPanel.Controls.Add($Script:Synchash.scriptbutton.$Trimmed.button)

}	

# Checks who is logged on and adds their NTUser.dat to the text. Will add dynamic background color as well.
function Get-Usernamedata {
	param (
		$Machine = $Script:Synchash.Machine.Text
	)
	#$User = cmd /c "query user /server:$($Machine)"
	#$User = #Sanitized#
	#$a = Get-ChildItem \\$Machine\C$\users\$User -Hidden -ErrorAction SilentlyContinue
	#$UserNT  = (($a | Where-Object {$_.Name -eq 'NTUSER.DAT'}).Length) /1mb
	#Return $UserNT
	#$Script:Synchash.Username.Text = $UserNT
	$Script:Synchash.Username.Text =  "" #Sanitized#
}

# This will run when a script button is clicked. The script will need to have a parameter with the machine name and this will introduce the machine into the script.
# Add (Param $Machine)
function Start-Action {
	($Machine = $Script:Synchash.Machine.Machine
	)
		Write-Host " MY $($this.Text) was clicked"
		
$Action = Get-ChildItem -Path $Script:Synchash.Agentdir -Recurse
$Action1 = $Action | Where-Object {$_.name -like "$($This.Text)"+".ps1"}
 
Start-Process "$($Action1.Fullname)" -Machine $Machine
		
}
#endregion

# Loading external assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


#Master  HashTable
$Script:syncHash = [hashtable]::Synchronized(@{
#$Script:Synchash = @{
	Form = New-Object System.Windows.Forms.Form
	Machine = New-Object System.Windows.Forms.TextBox
	Username = New-Object System.Windows.Forms.TextBox
	UserLabel = New-Object System.Windows.Forms.Label
	MachineLabel = New-Object System.Windows.Forms.Label
	flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
	button = New-Object System.Windows.Forms.Button	
	statusStrip = New-Object System.Windows.Forms.StatusStrip
	toolStripStatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
	BaseClipboard = ""
	scripts = @{}
	scriptbutton = @{}
	Fileshare = "" #Sanitized#
	Agentdir = "" #Sanitized# 
	
})	

# Machine
$Script:Synchash.Machine.Location = New-Object System.Drawing.Point(158, 12)
$Script:Synchash.Machine.Name = "Machine"
$Script:Synchash.Machine.Size = New-Object System.Drawing.Size(244, 22)
$Script:Synchash.Machine.TabIndex = 0


function Get-MachineTextChanged {
Write-Host "Text Change"
#	[void][System.Windows.Forms.MessageBox]::Show("The event handler Machine.Add_TextChanged is not implemented.")
#  Test-Connection -ComputerName $Machine -Count 1

}

$Script:Synchash.Machine.Add_TextChanged({ Get-MachineTextChanged })


# Username
$Script:Synchash.Username.Location = New-Object System.Drawing.Point(158, 41)
$Script:Synchash.Username.Name = "Username"
$Script:Synchash.Username.Size = New-Object System.Drawing.Size(244, 22)
$Script:Synchash.Username.TabIndex = 1
$Script:Synchash.Username.Text = Get-Usernamedata


# UserLabel
$Script:Synchash.UserLabel.AutoSize = $true
$Script:Synchash.UserLabel.Location = New-Object System.Drawing.Point(15, 44)
$Script:Synchash.UserLabel.Name = "UserLabel"
$Script:Synchash.UserLabel.Size = New-Object System.Drawing.Size(79, 17)
$Script:Synchash.UserLabel.TabIndex = 2
$Script:Synchash.UserLabel.Text = "User Name"

# MachineLabel
$Script:Synchash.MachineLabel.AutoSize = $true
$Script:Synchash.MachineLabel.Location = New-Object System.Drawing.Point(15, 13)
$Script:Synchash.MachineLabel.Name = "MachineLabel"
$Script:Synchash.MachineLabel.Size = New-Object System.Drawing.Size(61, 17)
$Script:Synchash.MachineLabel.TabIndex = 3
$Script:Synchash.MachineLabel.Text = "Machine"

# statusStrip
$Script:Synchash.statusStrip.ImageScalingSize = New-Object System.Drawing.Size(20, 20)
$Script:Synchash.statusStrip.Items.AddRange(@(
$Script:Synchash.toolStripStatusLabel))
$Script:Synchash.statusStrip.Location = New-Object System.Drawing.Point(0, 607)
$Script:Synchash.statusStrip.Name = "statusStrip"
$Script:Synchash.statusStrip.Size = New-Object System.Drawing.Size(444, 25)
$Script:Synchash.statusStrip.TabIndex = 5
$Script:Synchash.statusStrip.Text = "statusStrip"

# toolStripStatusLabel
$Script:Synchash.toolStripStatusLabel.Name = "toolStripStatusLabel"
$Script:Synchash.toolStripStatusLabel.Size = New-Object System.Drawing.Size(151, 20)
#$toolStripStatusLabel.Text = "toolStripStatusLabel"

# Form
$Script:Synchash.Form.ClientSize = New-Object System.Drawing.Size(460, 632)
$Script:Synchash.Form.Controls.AddRange(@(
    $Script:Synchash.statusStrip , 
    $Script:Synchash.flowLayoutPanel , 
    $Script:Synchash.MachineLabel , 
    $Script:Synchash.UserLabel , 
    $Script:Synchash.Username , 
    $Script:Synchash.Machine))
$Script:Synchash.Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedToolWindow
$Script:Synchash.Form.Name = "Form"
$Script:Synchash.Form.Text = "FixHub"


# flowLayoutPanel
$Script:Synchash.flowLayoutPanel.Controls.Add($Script:Synchash.button)
$Script:Synchash.flowLayoutPanel.Location = New-Object System.Drawing.Point(15, 77)
$Script:Synchash.flowLayoutPanel.Name = "flowLayoutPanel"
$Script:Synchash.flowLayoutPanel.Size = New-Object System.Drawing.Size(440, 528)
#$Script:Synchash.flowLayoutPanel.Size = New-Object System.Drawing.Size($Script:Synchash.Form.ClientSize.width, $Script:Synchash.Form.ClientSize.height)
$Script:Synchash.flowLayoutPanel.TabIndex = 4
$Script:Synchash.FlowLayoutPanel.AutoScroll = $true

function Start-FormClosing{ 
 	($_).Cancel= $False
	$Script:Synchash.Form.Dispose()
}


$Script:Synchash.Form.Add_FormClosing({ Start-FormClosing})
$Script:Synchash.Form.Add_Load({
	
	Start-CheckFiles  
	Update-Buttons
	Start-TimerStart 

})
$Script:Synchash.Form.ShowDialog()