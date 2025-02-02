# Define some variables up fromt
$tenantId = ""
$subscriptionId = ""
$devTestLabName = "ImageFactory"
$configurationFilesLocation = ""
$virtualmachineUsername = "labuser"
$virtualmachinePassword = ""

Add-AzureRmAccount -TenantId $tenantId  
Select-AzureRmSubscription -SubscriptionId $subscriptionId

# Scrape source code control for json files + create all VMs discovered
.\MakeGoldenImageVMs.ps1    -ConfigurationLocation $configurationFilesLocation `
                            -DevTestLabName $devTestLabName `
                            -machineUserName $virtualmachineUsername `
                            -machinePassword (ConvertTo-SecureString -String "$virtualmachinePassword" `
                            -AsPlainText -Force) `
                            -StandardTimeoutMinutes 60 `
                            -vmSize "Standard_DS2_v2"

# For all running VMs, save as images
.\SnapImagesFromVMs.ps1 -DevTestLabName $devTestLabName

# For all images, distribute to all labs who have 'signed up' for those images
.\DistributeImages.ps1 -ConfigurationLocation $configurationFilesLocation `
                       -SubscriptionId $subscriptionId `
                       -DevTestLabName $devTestLabName `
                       -maxConcurrentJobs 20

# Clean up any leftover stopped VMs in the factory
.\CleanUpFactory.ps1 -DevTestLabName $devTestLabName

# Retire all 'old' images from the factory lab and all other connected labs (cascade deletes)
.\RetireImages.ps1  -ConfigurationLocation  $configurationFilesLocation `
                    -SubscriptionId $subscriptionId `
                    -DevTestLabName $devTestLabName `
                    -ImagesToSave 2
