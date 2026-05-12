<%@ page contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="com.quickchat.utils.UserAgentUtils" %>
<%
    // === CRÉATION AUTO DE SESSION ===
    HttpSession userSession = request.getSession(true);
    Integer userId = (Integer) userSession.getAttribute("adminId");
    
    if (userId == null) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection connAuto = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
            PreparedStatement pstmtAuto = connAuto.prepareStatement("SELECT id, username FROM users WHERE role = 'admin' LIMIT 1");
            ResultSet rsAuto = pstmtAuto.executeQuery();
            if (rsAuto.next()) {
                userId = rsAuto.getInt("id");
                userSession.setAttribute("adminId", userId);
                userSession.setAttribute("adminUsername", rsAuto.getString("username"));
            }
            rsAuto.close();
            pstmtAuto.close();
            connAuto.close();
        } catch(Exception e) {
            e.printStackTrace();
        }
    }
    
    response.setContentType("application/json");
    response.setCharacterEncoding("UTF-8");
    
    if (userId == null) {
        out.print("{\"error\":\"Non authentifiÃ©\"}");
        return;
    }
    
    String action = request.getParameter("action");
    
    if ("history".equals(action)) {
        StringBuilder json = new StringBuilder();
        json.append("{\"history\":[");
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/quickchat", "root", "");
            
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
                json.append("\"ip\":\"").append(rs.getString("ip_address") != null ? rs.getString("ip_address").replace("\"", "\\\"") : "").append("\",");
                json.append("\"browser\":\"").append(rs.getString("browser") != null ? rs.getString("browser").replace("\"", "\\\"") : "").append("\",");
                json.append("\"os\":\"").append(rs.getString("os") != null ? rs.getString("os").replace("\"", "\\\"") : "").append("\",");
                json.append("\"device\":\"").append(rs.getString("device") != null ? rs.getString("device").replace("\"", "\\\"") : "").append("\",");
                json.append("\"location\":\"").append(rs.getString("location") != null ? rs.getString("location").replace("\"", "\\\"") : "").append("\",");
                json.append("\"login_time\":\"").append(rs.getTimestamp("login_time")).append("\",");
                json.append("\"status\":\"").append(rs.getString("login_status")).append("\"");
                json.append("}");
            }
            rs.close(); pstmt.close(); conn.close();
        } catch (Exception e) { 
            e.printStackTrace();
        }
        
        json.append("]}");
        out.print(json.toString());
    } else if ("current".equals(action)) {
        String ip = UserAgentUtils.getClientIpAddress(request);
        String userAgent = request.getHeader("User-Agent");
        UserAgentUtils.DeviceInfo deviceInfo = UserAgentUtils.parseUserAgent(userAgent);
        String location = UserAgentUtils.getLocationFromIp(ip);
        
        String json = String.format(
            "{\"ip\":\"%s\",\"browser\":\"%s\",\"os\":\"%s\",\"device\":\"%s\",\"location\":\"%s\"}",
            ip != null ? ip.replace("\"", "\\\"") : "",
            deviceInfo != null ? deviceInfo.browser.replace("\"", "\\\"") : "",
            deviceInfo != null ? deviceInfo.os.replace("\"", "\\\"") : "",
            deviceInfo != null ? deviceInfo.device.replace("\"", "\\\"") : "",
            location != null ? location.replace("\"", "\\\"") : ""
        );
        out.print(json);
    } else {
        out.print("{\"error\":\"Action inconnue\"}");
    }
%>