package com.quickchat.servlet;

import com.quickchat.utils.UserAgentUtils;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.time.LocalDateTime;

@WebServlet("/immo/admin/session-manager")
public class SessionManagerServlet extends HttpServlet {
    
    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("adminId");
        
        if (userId == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\":\"Non authentifié\"}");
            return;
        }
        
        String action = request.getParameter("action");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        if ("current".equals(action)) {
            getCurrentSession(request, response, userId);
        } else if ("history".equals(action)) {
            getLoginHistory(response, userId);
        } else {
            response.getWriter().write("{\"error\":\"Action inconnue\"}");
        }
    }
    
    private void getCurrentSession(HttpServletRequest request, HttpServletResponse response, int userId) 
            throws IOException {
        
        String ip = UserAgentUtils.getClientIpAddress(request);
        String userAgent = request.getHeader("User-Agent");
        UserAgentUtils.DeviceInfo deviceInfo = UserAgentUtils.parseUserAgent(userAgent);
        String location = UserAgentUtils.getLocationFromIp(ip);
        
        String json = String.format(
            "{\"ip\":\"%s\",\"browser\":\"%s\",\"os\":\"%s\",\"device\":\"%s\",\"location\":\"%s\"}",
            escapeJson(ip), escapeJson(deviceInfo.browser), escapeJson(deviceInfo.os),
            escapeJson(deviceInfo.device), escapeJson(location)
        );
        response.getWriter().write(json);
    }
    
    private void getLoginHistory(HttpServletResponse response, int userId) throws IOException {
        StringBuilder json = new StringBuilder();
        json.append("{\"history\":[");
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            PreparedStatement pstmt = conn.prepareStatement(
                "SELECT ip_address, browser, os, device, location, login_time, login_status " +
                "FROM login_history WHERE user_id = ? ORDER BY login_time DESC LIMIT 10"
            );
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            
            boolean first = true;
            while (rs.next()) {
                if (!first) json.append(",");
                first = false;
                json.append("{");
                json.append("\"ip\":\"").append(escapeJson(rs.getString("ip_address"))).append("\",");
                json.append("\"browser\":\"").append(escapeJson(rs.getString("browser"))).append("\",");
                json.append("\"os\":\"").append(escapeJson(rs.getString("os"))).append("\",");
                json.append("\"device\":\"").append(escapeJson(rs.getString("device"))).append("\",");
                json.append("\"location\":\"").append(escapeJson(rs.getString("location"))).append("\",");
                json.append("\"login_time\":\"").append(rs.getTimestamp("login_time")).append("\",");
                json.append("\"status\":\"").append(rs.getString("login_status")).append("\"");
                json.append("}");
            }
            rs.close(); pstmt.close(); conn.close();
        } catch (Exception e) { e.printStackTrace(); }
        
        json.append("]}");
        response.getWriter().write(json.toString());
    }
    
    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}