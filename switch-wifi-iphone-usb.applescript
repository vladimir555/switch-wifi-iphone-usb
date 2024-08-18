-- IP-адрес для проверки доступности интернета
global checkIP
set checkIP to "8.8.8.8"

-- Функция для записи сообщений в лог
on logMessage(message)
    do shell script "echo " & quoted form of message & " >> ~/switch-wifi.log"
end logMessage

-- Функция для получения списка всех сетевых сервисов
on getAllNetworkServices()
    try
        set networkServices to do shell script "networksetup -listallnetworkservices | sed 1d | awk '{if (substr($0, 1, 1) == \"*\") print substr($0, 2); else print $0}'"
        return paragraphs of networkServices
    on error errMsg
        logMessage("Ошибка при получении списка сетевых сервисов: " & errMsg)
        return {}
    end try
end getAllNetworkServices

-- Функция для получения имени текущей Wi-Fi сети
on getWiFiServiceName()
    try
        set wifiName to do shell script "networksetup -getairportnetwork en0 | awk -F': ' '{print $2}'"
        return "Wi-Fi"
    on error errMsg
        logMessage("Ошибка при получении имени Wi-Fi сети: " & errMsg)
        return ""
    end try
end getWiFiServiceName

-- Функция для определения имени сети iPhone по USB
on getIPhoneUSBServiceName()
    try
        set iphoneUSB to do shell script "networksetup -listnetworkserviceorder | grep 'iPhone USB' | head -n 1 | awk -F'\\) ' '{print $2}'"
        return "iPhone USB"
    on error errMsg
        logMessage("Ошибка при получении имени iPhone USB: " & errMsg)
        return ""
    end try
end getIPhoneUSBServiceName

-- Функция для проверки доступности интернета через Wi-Fi
on isInternetAvailableViaWiFi()
    set wifiInterface to "en0"
    try
        set script_string to "ping -c 3 -b " & wifiInterface & " " & checkIP & " | grep '10 packets received'"
        logMessage(script_string)
        set pingResult to do shell script script_string
        return (pingResult is not "")
    on error errMsg
        logMessage("Ошибка при проверке интернета через Wi-Fi: " & errMsg)
        return false
    end try
end isInternetAvailableViaWiFi

-- Функция для установки приоритета сети
on setNetworkPriority(primaryService, secondaryService)
    -- Получаем все доступные сетевые сервисы
    set allServices to getAllNetworkServices()

    -- Переставляем приоритеты
    set serviceOrder to {}
    set end of serviceOrder to primaryService
    set end of serviceOrder to secondaryService

    repeat with service in allServices
        if service is not in serviceOrder then
            set end of serviceOrder to service
        end if
    end repeat

    -- Формируем команду для изменения приоритета
    set quotedServices  to "\"" & join(serviceOrder, "\" \"")
    set priorityCommand to "networksetup -ordernetworkservices " & quotedServices

    -- Отладочная информация
    logMessage("Выполнение команды: " & priorityCommand)

    try
        do shell script priorityCommand
    on error errMsg
        logMessage("Ошибка при установке приоритета: " & errMsg)
    end try
end setNetworkPriority

-- Функция объединения элементов в строку
on join(listItems, delimiter)
    set theString to ""
    repeat with anItem in listItems
        set theString to theString & anItem & delimiter
    end repeat
    return text 1 thru -2 of theString
end join

-- Основная логика
on mainLogic()
    set wifiServiceName         to getWiFiServiceName()
    set iPhoneUSBServiceName   to getIPhoneUSBServiceName()
    set currentServiceName     to wifiServiceName

    repeat

        if wifiServiceName is "" then
            logMessage("Ошибка: не удалось получить имя сети Wi-Fi.")
            delay 60
            return
        else
            logMessage("Wi-Fi сеть: " & wifiServiceName)
        end if

        if iPhoneUSBServiceName is "" then
            logMessage("Ошибка: не удалось найти подключение iPhone USB.")
            delay 60
            return
        else
            logMessage("iPhone USB: " & iPhoneUSBServiceName)
        end if

        -- Проверка доступности интернета через Wi-Fi
        if isInternetAvailableViaWiFi() then
            logMessage("Переключение на " & wifiServiceName & " ...")
            if currentServiceName is not wifiServiceName then
                setNetworkPriority(wifiServiceName, iPhoneUSBServiceName)
                set currentServiceName to wifiServiceName
            else
                logMessage(wifiServiceName & " уже имеет приоритет.")
            end if
        else
        logMessage("Переключение на " & iPhoneUSBServiceName & " ...")
            if currentServiceName is not iPhoneUSBServiceName then
                setNetworkPriority(iPhoneUSBServiceName, wifiServiceName)
                set currentServiceName to iPhoneUSBServiceName
            else
                logMessage(iPhoneUSBServiceName & " уже имеет приоритет.")
            end if
        end if

        delay 60 -- Периодическая проверка каждые 60 секунд
    end repeat
end mainLogic

-- Запуск основной логики
mainLogic()
