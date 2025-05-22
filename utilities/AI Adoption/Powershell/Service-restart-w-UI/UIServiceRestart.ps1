# Load Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Helper function to retrieve services and prompt for selection
function Get-ServiceSelection {
    param ($serverName)

    $services = Get-Service -ComputerName $serverName | Select-Object -ExpandProperty DisplayName
    $serviceForm = New-Object System.Windows.Forms.Form
    $serviceForm.Text = "Select a Service"
    $serviceForm.Size = New-Object System.Drawing.Size(350,300)
    $serviceForm.StartPosition = "CenterScreen"

    $serviceListBox = New-Object System.Windows.Forms.ListBox
    $serviceListBox.Location = New-Object System.Drawing.Point(10,10)
    $serviceListBox.Size = New-Object System.Drawing.Size(310,200)
    $serviceListBox.SelectionMode = 'One'
    $serviceListBox.Items.AddRange($services)

    $serviceSelectButton = New-Object System.Windows.Forms.Button
    $serviceSelectButton.Text = "OK"
    $serviceSelectButton.Location = New-Object System.Drawing.Point(125,220)
    $serviceSelectButton.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $serviceForm.Controls.Add($serviceListBox)
    $serviceForm.Controls.Add($serviceSelectButton)
    $serviceForm.AcceptButton = $serviceSelectButton

    if ($serviceForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $serviceListBox.SelectedItem
    }

    return $null
}

# Function to restart IIS on the remote server
function Restart-IISOnRemoteServer {
    param ($serverName)
    Invoke-Command -ComputerName $serverName -ScriptBlock { Restart-Service 'W3SVC' -Force }
}

# Function to restart a specified service on the remote server
function Restart-ServiceOnRemoteServer {
    param ($serverName, $serviceName)
    Invoke-Command -ComputerName $serverName -ScriptBlock {
        param ($serviceName)
        Restart-Service -Name $serviceName -Force
    } -ArgumentList $serviceName
}

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Server Management Tool"
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = "CenterScreen"

# Label for server name
$label = New-Object System.Windows.Forms.Label
$label.Text = "Server Name:"
$label.Location = New-Object System.Drawing.Point(10,20)
$form.Controls.Add($label)

# Textbox for server name input
$serverNameBox = New-Object System.Windows.Forms.TextBox
$serverNameBox.Location = New-Object System.Drawing.Point(100, 20)
$serverNameBox.Width = 250
$form.Controls.Add($serverNameBox)

# Dropdown for operation selection
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(10, 60)
$comboBox.Width = 340
$comboBox.Items.AddRange(@("Restart IIS", "Restart Windows Service"))
$form.Controls.Add($comboBox)

# Button to apply the selected operation
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(10, 100)
$button.Text = "Apply"
$button.Add_Click({
    $operation = $comboBox.SelectedItem
    $serverName = $serverNameBox.Text

    if (-not [string]::IsNullOrEmpty($operation)) {
        if ($operation -eq "Restart IIS") {
            Restart-IISOnRemoteServer -serverName $serverName
            [System.Windows.Forms.MessageBox]::Show("IIS Restarted on $serverName.")
        }
        elseif ($operation -eq "Restart Windows Service") {
            $serviceName = Get-ServiceSelection -serverName $serverName
            if ($null -ne $serviceName) {
                Restart-ServiceOnRemoteServer -serverName $serverName -serviceName $serviceName
                [System.Windows.Forms.MessageBox]::Show("Service '$serviceName' Restarted on $serverName.")
            }
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select an operation.")
    }
})
$form.Controls.Add($button)

# Start the form
[void]$form.ShowDialog()
