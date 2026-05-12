package com.quickchat.utils;

import javax.servlet.http.HttpServletRequest;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class UserAgentUtils {
    
    // Obtenir l'adresse IP réelle du client
    public static String getClientIpAddress(HttpServletRequest request) {
        String ipAddress = request.getHeader("X-Forwarded-For");
        if (ipAddress == null || ipAddress.isEmpty() || "unknown".equalsIgnoreCase(ipAddress)) {
            ipAddress = request.getHeader("Proxy-Client-IP");
        }
        if (ipAddress == null || ipAddress.isEmpty() || "unknown".equalsIgnoreCase(ipAddress)) {
            ipAddress = request.getHeader("WL-Proxy-Client-IP");
        }
        if (ipAddress == null || ipAddress.isEmpty() || "unknown".equalsIgnoreCase(ipAddress)) {
            ipAddress = request.getRemoteAddr();
        }
        if (ipAddress != null && ipAddress.contains(",")) {
            ipAddress = ipAddress.split(",")[0].trim();
        }
        
        // Convertir l'IPv6 localhost en affichage plus clair
        if (ipAddress != null) {
            if ("0:0:0:0:0:0:0:1".equals(ipAddress) || "::1".equals(ipAddress) || "127.0.0.1".equals(ipAddress)) {
                ipAddress = "localhost (vous)";
            } else if (ipAddress.startsWith("192.168.")) {
                ipAddress = ipAddress + " (réseau local)";
            } else if (ipAddress.startsWith("10.") || ipAddress.startsWith("172.")) {
                ipAddress = ipAddress + " (réseau privé)";
            }
        }
        
        return ipAddress != null ? ipAddress : "0.0.0.0";
    }
    
    // Obtenir la géolocalisation à partir de l'IP
    public static String getLocationFromIp(String ip) {
        if (ip == null) return "Localisation inconnue";
        if (ip.contains("localhost") || ip.equals("127.0.0.1") || ip.startsWith("192.168.") || ip.equals("0:0:0:0:0:0:0:1") || ip.equals("::1")) {
            return "Développement local";
        }
        if (ip.startsWith("10.") || ip.startsWith("172.")) {
            return "Réseau privé";
        }
        try {
            String url = "http://ip-api.com/json/" + ip + "?fields=status,city,regionName,country";
            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            conn.setConnectTimeout(3000);
            conn.setRequestMethod("GET");
            
            BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
            StringBuilder response = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) response.append(line);
            reader.close();
            
            String json = response.toString();
            if (json.contains("\"status\":\"success\"")) {
                String city = extractValue(json, "city");
                String region = extractValue(json, "regionName");
                String country = extractValue(json, "country");
                return city + ", " + region + ", " + country;
            }
        } catch (Exception e) {
            System.err.println("Erreur géolocalisation: " + e.getMessage());
        }
        return "Localisation inconnue";
    }
    
    private static String extractValue(String json, String key) {
        String pattern = "\"" + key + "\":\"";
        int start = json.indexOf(pattern);
        if (start == -1) return "";
        start += pattern.length();
        int end = json.indexOf("\"", start);
        if (end == -1) return "";
        return json.substring(start, end);
    }
    
    // Analyser le User-Agent (VERSION CORRIGÉE)
    public static DeviceInfo parseUserAgent(String userAgent) {
        DeviceInfo info = new DeviceInfo();
        if (userAgent == null) {
            info.browser = "Inconnu"; 
            info.os = "Inconnu"; 
            info.device = "Inconnu";
            return info;
        }
        
        // DÉTECTION OS (ordre important : Windows d'abord)
        if (userAgent.contains("Windows NT")) {
            if (userAgent.contains("Windows NT 10.0")) {
                info.os = "Windows 10/11";
            } else if (userAgent.contains("Windows NT 6.3")) {
                info.os = "Windows 8.1";
            } else if (userAgent.contains("Windows NT 6.2")) {
                info.os = "Windows 8";
            } else if (userAgent.contains("Windows NT 6.1")) {
                info.os = "Windows 7";
            } else {
                info.os = "Windows";
            }
            info.device = "💻 Ordinateur";
        } 
        else if (userAgent.contains("Mac OS X") || userAgent.contains("Macintosh")) {
            info.os = "macOS";
            info.device = "💻 Ordinateur";
        } 
        else if (userAgent.contains("Linux") && !userAgent.contains("Android")) {
            info.os = "Linux";
            info.device = "💻 Ordinateur";
        } 
        else if (userAgent.contains("Android")) {
            info.os = "Android";
            info.device = "📱 Mobile";
        } 
        else if (userAgent.contains("iPhone")) {
            info.os = "iOS";
            info.device = "📱 Mobile";
        } 
        else if (userAgent.contains("iPad")) {
            info.os = "iOS";
            info.device = "📟 Tablette";
        } 
        else {
            info.os = "Inconnu";
            info.device = "💻 Ordinateur";
        }
        
        // DÉTECTION NAVIGATEUR
        if (userAgent.contains("Edg") || userAgent.contains("Edge")) {
            info.browser = "Microsoft Edge";
        } else if (userAgent.contains("OPR") || userAgent.contains("Opera")) {
            info.browser = "Opera";
        } else if (userAgent.contains("Chrome") && !userAgent.contains("Edg") && !userAgent.contains("OPR")) {
            info.browser = "Google Chrome";
        } else if (userAgent.contains("Firefox") && !userAgent.contains("Seamonkey")) {
            info.browser = "Mozilla Firefox";
        } else if (userAgent.contains("Safari") && !userAgent.contains("Chrome") && !userAgent.contains("Edg")) {
            info.browser = "Apple Safari";
        } else if (userAgent.contains("MSIE") || userAgent.contains("Trident")) {
            info.browser = "Internet Explorer";
        } else {
            info.browser = "Autre";
        }
        
        return info;
    }
    
    public static class DeviceInfo {
        public String browser;
        public String os;
        public String device;
    }
}