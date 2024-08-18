-- IP-����� ��� �������� ����������� ���������
global checkIP
set checkIP to "8.8.8.8"

-- ������� ��� ������ ��������� � ���
on logMessage(message)
    do shell script "echo " & quoted form of message & " >> ~/switch-wifi.log"
end logMessage

-- ������� ��� ��������� ������ ���� ������� ��������
on getAllNetworkServices()
    try
        set networkServices to do shell script "networksetup -listallnetworkservices | sed 1d | awk '{if (substr($0, 1, 1) == \"*\") print substr($0, 2); else print $0}'"
        return paragraphs of networkServices
    on error errMsg
        logMessage("������ ��� ��������� ������ ������� ��������: " & errMsg)
        return {}
    end try
end getAllNetworkServices

-- ������� ��� ��������� ����� ������� Wi-Fi ����
on getWiFiServiceName()
    try
        set wifiName to do shell script "networksetup -getairportnetwork en0 | awk -F': ' '{print $2}'"
        return "Wi-Fi"
    on error errMsg
        logMessage("������ ��� ��������� ����� Wi-Fi ����: " & errMsg)
        return ""
    end try
end getWiFiServiceName

-- ������� ��� ����������� ����� ���� iPhone �� USB
on getIPhoneUSBServiceName()
    try
        set iphoneUSB to do shell script "networksetup -listnetworkserviceorder | grep 'iPhone USB' | head -n 1 | awk -F'\\) ' '{print $2}'"
        return "iPhone USB"
    on error errMsg
        logMessage("������ ��� ��������� ����� iPhone USB: " & errMsg)
        return ""
    end try
end getIPhoneUSBServiceName

-- ������� ��� �������� ����������� ��������� ����� Wi-Fi
on isInternetAvailableViaWiFi()
    set wifiInterface to "en0"
    try
        set script_string to "ping -c 3 -b " & wifiInterface & " " & checkIP & " | grep '10 packets received'"
        logMessage(script_string)
        set pingResult to do shell script script_string
        return (pingResult is not "")
    on error errMsg
        logMessage("������ ��� �������� ��������� ����� Wi-Fi: " & errMsg)
        return false
    end try
end isInternetAvailableViaWiFi

-- ������� ��� ��������� ���������� ����
on setNetworkPriority(primaryService, secondaryService)
    -- �������� ��� ��������� ������� �������
    set allServices to getAllNetworkServices()

    -- ������������ ����������
    set serviceOrder to {}
    set end of serviceOrder to primaryService
    set end of serviceOrder to secondaryService

    repeat with service in allServices
        if service is not in serviceOrder then
            set end of serviceOrder to service
        end if
    end repeat

    -- ��������� ������� ��� ��������� ����������
    set quotedServices  to "\"" & join(serviceOrder, "\" \"")
    set priorityCommand to "networksetup -ordernetworkservices " & quotedServices

    -- ���������� ����������
    logMessage("���������� �������: " & priorityCommand)

    try
        do shell script priorityCommand
    on error errMsg
        logMessage("������ ��� ��������� ����������: " & errMsg)
    end try
end setNetworkPriority

-- ������� ����������� ��������� � ������
on join(listItems, delimiter)
    set theString to ""
    repeat with anItem in listItems
        set theString to theString & anItem & delimiter
    end repeat
    return text 1 thru -2 of theString
end join

-- �������� ������
on mainLogic()
    set wifiServiceName         to getWiFiServiceName()
    set iPhoneUSBServiceName   to getIPhoneUSBServiceName()
    set currentServiceName     to wifiServiceName

    repeat

        if wifiServiceName is "" then
            logMessage("������: �� ������� �������� ��� ���� Wi-Fi.")
            delay 60
            return
        else
            logMessage("Wi-Fi ����: " & wifiServiceName)
        end if

        if iPhoneUSBServiceName is "" then
            logMessage("������: �� ������� ����� ����������� iPhone USB.")
            delay 60
            return
        else
            logMessage("iPhone USB: " & iPhoneUSBServiceName)
        end if

        -- �������� ����������� ��������� ����� Wi-Fi
        if isInternetAvailableViaWiFi() then
            logMessage("������������ �� " & wifiServiceName & " ...")
            if currentServiceName is not wifiServiceName then
                setNetworkPriority(wifiServiceName, iPhoneUSBServiceName)
                set currentServiceName to wifiServiceName
            else
                logMessage(wifiServiceName & " ��� ����� ���������.")
            end if
        else
        logMessage("������������ �� " & iPhoneUSBServiceName & " ...")
            if currentServiceName is not iPhoneUSBServiceName then
                setNetworkPriority(iPhoneUSBServiceName, wifiServiceName)
                set currentServiceName to iPhoneUSBServiceName
            else
                logMessage(iPhoneUSBServiceName & " ��� ����� ���������.")
            end if
        end if

        delay 60 -- ������������� �������� ������ 60 ������
    end repeat
end mainLogic

-- ������ �������� ������
mainLogic()
