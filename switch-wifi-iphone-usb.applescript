-- IP address to check for internet availability
global pingIP
global pingCount
set pingIP      to "8.8.8.8"
set pingCount   to 10

-- Function to log messages
on logMessage(message)
    do shell script "echo " & quoted form of message & " >> ~/switch-wifi-iphone-usb.log"
end logMessage

-- Function to get the list of all network services
on getAllNetworkServices()
    try
        set networkServices to do shell script "networksetup -listallnetworkservices | sed 1d | awk '{if (substr($0, 1, 1) == \"*\") print substr($0, 2); else print $0}'"
        return paragraphs of networkServices
    on error errMsg
        logMessage("Error getting list of network services: " & errMsg)
        return {}
    end try
end getAllNetworkServices

-- Function to get the current Wi-Fi network name
on getWiFiServiceName()
    try
        set wifiName to do shell script "networksetup -getairportnetwork en0 | awk -F': ' '{print $2}'"
        return "Wi-Fi"
    on error errMsg
        logMessage("Error getting Wi-Fi network name: " & errMsg)
        return ""
    end try
end getWiFiServiceName

-- Function to get the name of the iPhone USB network
on getIPhoneUSBServiceName()
    try
        set iphoneUSB to do shell script "networksetup -listnetworkserviceorder | grep 'iPhone USB' | head -n 1 | awk -F'\\) ' '{print $2}'"
        return "iPhone USB"
    on error errMsg
        logMessage("Error getting iPhone USB network name: " & errMsg)
        return ""
    end try
end getIPhoneUSBServiceName

-- Function to check internet availability via Wi-Fi
on isInternetAvailableViaWiFi()
    set wifiInterface to "en0"
    try
        set script_string to "ping -c " & pingCount & " -b " & wifiInterface & " " & pingIP & " | grep '" & pingCount & " packets received'"
        logMessage(script_string)
        set pingResult to do shell script script_string
        return (pingResult is not "")
    on error errMsg
        logMessage("Error checking internet via Wi-Fi: " & errMsg)
        return false
    end try
end isInternetAvailableViaWiFi

-- Function to set network priority
on setNetworkPriority(primaryService, secondaryService)
    -- Get all available network services
    set allServices to getAllNetworkServices()

    -- Rearrange priorities
    set serviceOrder to {}
    set end of serviceOrder to primaryService
    set end of serviceOrder to secondaryService

    repeat with service in allServices
        if service is not in serviceOrder then
            set end of serviceOrder to service
        end if
    end repeat

    -- Form command to change priority
    set quotedServices  to "\"" & join(serviceOrder, "\" \"")
    set priorityCommand to "networksetup -ordernetworkservices " & quotedServices

    -- Debug information
    logMessage(priorityCommand)

    try
        do shell script priorityCommand
    on error errMsg
        logMessage("Error setting priority: " & errMsg)
    end try
end setNetworkPriority

-- Function to join elements into a string
on join(listItems, delimiter)
    set theString to ""
    repeat with anItem in listItems
        set theString to theString & anItem & delimiter
    end repeat
    return text 1 thru -2 of theString
end join

-- Main logic
on mainLogic()
    set wifiServiceName         to getWiFiServiceName()
    set iPhoneUSBServiceName   to getIPhoneUSBServiceName()
    set currentServiceName     to wifiServiceName

    repeat

        if wifiServiceName is "" then
            logMessage("Error: could not retrieve Wi-Fi network name.")
            delay 60
            return
        end if

        if iPhoneUSBServiceName is "" then
            logMessage("Error: could not find iPhone USB connection.")
            delay 60
            return
        end if

        -- Check internet availability via Wi-Fi
        if isInternetAvailableViaWiFi() then
            logMessage("Switching to " & wifiServiceName & " ...")
            if currentServiceName is not wifiServiceName then
                setNetworkPriority(wifiServiceName, iPhoneUSBServiceName)
                set currentServiceName to wifiServiceName
            else
                logMessage(wifiServiceName & " already has priority.")
            end if
        else
            logMessage("Switching to " & iPhoneUSBServiceName & " ...")
            if currentServiceName is not iPhoneUSBServiceName then
                setNetworkPriority(iPhoneUSBServiceName, wifiServiceName)
                set currentServiceName to iPhoneUSBServiceName
            else
                logMessage(iPhoneUSBServiceName & " already has priority.")
            end if
        end if

        delay 60 -- Periodic check every 60 seconds
    end repeat
end mainLogic

-- Start main logic
mainLogic()
